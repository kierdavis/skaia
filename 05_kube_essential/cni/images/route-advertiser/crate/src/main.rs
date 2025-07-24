use self::util::DedupAdjacentStreamExt;
use futures_util::{
  future::ready,
  pin_mut,
  stream::{select, FusedStream, StreamExt},
};
use k8s_openapi::api::core::v1::{Node, Service};
use k8s_openapi::api::discovery::v1::{Endpoint, EndpointSlice};
use k8s_openapi::apimachinery::pkg::apis::meta::v1::ObjectMeta;
use kube::{
  runtime::{reflector, watcher, WatchStreamExt},
  Api,
};
use std::collections::BTreeSet;
use std::process::ExitCode;
use thiserror::Error;
use tokio::process::Command;

mod util;

fn main() -> ExitCode {
  env_logger::init();
  match app() {
    Ok(_) => unreachable!(),
    Err(err) => {
      let err_msg = err.to_string();
      log::error!("fatal: {}", err_msg);
      let _ = std::fs::write("/dev/termination-log", err_msg);
      ExitCode::FAILURE
    }
  }
}

#[tokio::main(flavor = "current_thread")]
async fn app() -> Result<(), Error> {
  let this_node_name = get_this_node_name()?;
  let service_networks = get_service_networks()?;
  let routes_st = watch_routes(init_kube_client()?, &this_node_name, &service_networks);
  pin_mut!(routes_st);
  loop {
    let routes = routes_st.next().await.unwrap();
    log::info!("routes = {:?}", routes);
    if let Err(err) = advertise(routes).await {
      log::error!("failed to advertise routes: {}", err);
    }
  }
}

fn init_kube_client() -> Result<kube::Client, Error> {
  let cfg = kube::Config::incluster().map_err(Error::KubeConfig)?;
  let client = kube::Client::try_from(cfg).map_err(Error::KubeClient)?;
  log::debug!("kube_client initialised");
  Ok(client)
}

fn get_this_node_name() -> Result<String, Error> {
  const VAR: &'static str = "THIS_NODE_NAME";
  let val = std::env::var(VAR).map_err(Error::read_env(VAR))?;
  log::debug!("this_node_name = {}", val);
  Ok(val)
}

fn get_service_networks() -> Result<BTreeSet<String>, Error> {
  const VAR: &'static str = "SERVICE_NETWORKS";
  let s = std::env::var(VAR).map_err(Error::read_env(VAR))?;
  let val = s.split(',').map(String::from).collect();
  log::debug!("service_networks = {:?}", val);
  Ok(val)
}

fn watch_routes<'a>(
  kube_client: kube::Client,
  this_node_name: &'a str,
  service_networks: &'a BTreeSet<String>,
) -> impl FusedStream<Item = BTreeSet<String>> + Send + 'a {
  #[derive(Debug, Default)]
  struct State {
    pod_routes: Vec<String>,
    svc_routes: BTreeSet<String>,
  }
  #[derive(Debug)]
  enum Event {
    PodRoutesChanged(Vec<String>),
    SvcRoutesChanged(BTreeSet<String>),
  }
  select(
    watch_pod_routes(kube_client.clone(), this_node_name).map(Event::PodRoutesChanged),
    watch_service_routes(kube_client, this_node_name, service_networks)
      .map(Event::SvcRoutesChanged),
  )
  .scan(State::default(), |state, event| {
    ready(Some({
      match event {
        Event::PodRoutesChanged(new) => {
          state.pod_routes = new;
        }
        Event::SvcRoutesChanged(new) => {
          state.svc_routes = new;
        }
      }
      let mut routes = state.svc_routes.clone();
      routes.extend(state.pod_routes.iter().cloned());
      routes
    }))
  })
  .dedup_adjacent()
}

fn watch_pod_routes(
  kube_client: kube::Client,
  this_node_name: &str,
) -> impl FusedStream<Item = Vec<String>> + Send + '_ {
  watch_node(kube_client, this_node_name)
    .map(|node| node.spec.unwrap().pod_cidrs.unwrap_or_else(Vec::new))
}

fn watch_node(kube_client: kube::Client, name: &str) -> impl FusedStream<Item = Node> + Send + '_ {
  fn node_name_equals(a: &Node, b: &str) -> bool {
    a.metadata.name.as_ref().map_or("", String::as_str) == b
  }
  watcher(Api::all(kube_client), watcher::Config::default())
    .default_backoff()
    .applied_objects()
    .filter_map(move |result| {
      ready(match result {
        Ok(node) if node_name_equals(&node, name) => Some(node),
        Ok(_) => None,
        Err(err) => {
          log::warn!("failed to watch Nodes (will back off and retry): {}", err);
          None
        }
      })
    })
    .fuse()
}

fn watch_service_routes<'a>(
  kube_client: kube::Client,
  this_node_name: &'a str,
  service_networks: &'a BTreeSet<String>,
) -> impl FusedStream<Item = BTreeSet<String>> + Send + 'a {
  let (all_endpoint_slices, endpoint_slice_changes) =
    watch_all_endpoint_slices(kube_client.clone());
  let (all_services, service_changes) = watch_all_services(kube_client);
  futures_util::stream::select(service_changes, endpoint_slice_changes).map(move |MaybeChanged| {
    compute_service_routes(
      &all_endpoint_slices,
      &all_services,
      this_node_name,
      service_networks,
    )
  })
}

fn watch_all_endpoint_slices(
  kube_client: kube::Client,
) -> (
  reflector::Store<EndpointSlice>,
  impl FusedStream<Item = MaybeChanged> + Send,
) {
  let (reader, writer) = reflector::store();
  let changes = reflector(
    writer,
    watcher(Api::all(kube_client), watcher::Config::default())
      .default_backoff()
      .modify(shrink_endpoint_slice_memory_usage),
  )
  .filter_map(move |result| {
    ready(match result {
      Ok(_) => Some(MaybeChanged),
      Err(err) => {
        log::warn!(
          "failed to watch EndpointSlices (will back off and retry): {}",
          err
        );
        None
      }
    })
  })
  .fuse();
  (reader, changes)
}

fn watch_all_services(
  kube_client: kube::Client,
) -> (
  reflector::Store<Service>,
  impl FusedStream<Item = MaybeChanged> + Send,
) {
  let (reader, writer) = reflector::store();
  let changes = reflector(
    writer,
    watcher(Api::all(kube_client), watcher::Config::default())
      .default_backoff()
      .modify(shrink_service_memory_usage),
  )
  .filter_map(move |result| {
    ready(match result {
      Ok(_) => Some(MaybeChanged),
      Err(err) => {
        log::warn!(
          "failed to watch Services (will back off and retry): {}",
          err
        );
        None
      }
    })
  })
  .fuse();
  (reader, changes)
}

fn compute_service_routes(
  all_endpoint_slices: &reflector::Store<EndpointSlice>,
  all_services: &reflector::Store<Service>,
  this_node_name: &str,
  service_networks: &BTreeSet<String>,
) -> BTreeSet<String> {
  fn endpoint_is_ready(ep: &Endpoint) -> bool {
    match ep.conditions {
      Some(ref conds) => conds.ready.unwrap_or(true),
      None => true,
    }
  }
  fn endpoint_node_name_equals(a: &Endpoint, b: &str) -> bool {
    a.node_name.as_ref().map_or("", String::as_str) == b
  }
  fn addr_to_cidr(addr: &impl AsRef<str>) -> String {
    let addr = addr.as_ref();
    let mut cidr = String::from(addr);
    cidr.push_str(if addr.contains(':') { "/128" } else { "/32" });
    cidr
  }
  log::debug!("compute_service_routes: begin");
  let mut result = service_networks.clone();
  for eps in all_endpoint_slices.state() {
    let ns = eps.metadata.namespace.as_ref().unwrap();
    let eps_name = eps.metadata.name.as_ref().unwrap();
    let has_ep_on_this_node = eps
      .endpoints
      .iter()
      .any(|ep| endpoint_is_ready(ep) && endpoint_node_name_equals(ep, this_node_name));
    let has_ep_on_any_node = eps
      .endpoints
      .iter()
      .any(|ep| endpoint_is_ready(ep) && ep.node_name.is_some());
    let should_advertise = has_ep_on_this_node || !has_ep_on_any_node;
    log::debug!(
      "compute_service_routes: EndpointSlice {}/{} should_advertise={}",
      ns,
      eps_name,
      should_advertise,
    );
    if !should_advertise {
      continue;
    }
    const LABEL: &'static str = "kubernetes.io/service-name";
    let svc_name = match eps
      .metadata
      .labels
      .as_ref()
      .and_then(|labels| labels.get(LABEL))
    {
      Some(x) => x,
      None => {
        log::warn!(
          "EndpointSlice {}/{} has no {} label; skipping",
          ns,
          eps_name,
          LABEL
        );
        continue;
      }
    };
    let svc_ref = reflector::ObjectRef::new(svc_name).within(ns);
    let svc = match all_services.get(&svc_ref) {
      Some(x) => x,
      None => {
        log::warn!(
          "no data available for Service {}/{} referenced by EndpointSlice {}/{}; skipping",
          ns,
          svc_ref.name,
          ns,
          eps_name
        );
        continue;
      }
    };
    let svc_addrs = svc
      .spec
      .as_ref()
      .unwrap()
      .cluster_ips
      .as_ref()
      .map_or(&[] as &[_], Vec::as_slice);
    log::debug!(
      "compute_service_routes: Service {}/{} svc_addrs={:?}",
      ns,
      svc_ref.name,
      svc_addrs,
    );
    result.extend(
      svc_addrs
        .iter()
        .filter(|a| a.as_str() != "None")
        .map(addr_to_cidr),
    );
  }
  log::debug!("compute_service_routes: result={:?}", result);
  result
}

fn shrink_endpoint_slice_memory_usage(eps: &mut EndpointSlice) {
  eps.address_type = String::new();
  for ep in eps.endpoints.iter_mut() {
    ep.addresses = Vec::new();
    // ep.conditions owns no heap allocations
    ep.deprecated_topology = None;
    ep.hints = None;
    ep.hostname = None;
    // ep.node_name is explicitly used
    ep.target_ref = None;
    ep.zone = None;
  }
  shrink_objectmeta_memory_usage(&mut eps.metadata);
  eps.ports = None;
}

fn shrink_service_memory_usage(svc: &mut Service) {
  shrink_objectmeta_memory_usage(&mut svc.metadata);
  if let Some(spec) = svc.spec.as_mut() {
    // spec.allocate_load_balancer_node_ports owns no heap allocations
    spec.cluster_ip = None;
    // spec.cluster_ips is explicitly used
    spec.external_ips = None;
    spec.external_name = None;
    spec.external_traffic_policy = None;
    // spec.health_check_node_port owns no heap allocations
    spec.internal_traffic_policy = None;
    spec.ip_families = None;
    spec.ip_family_policy = None;
    spec.load_balancer_class = None;
    spec.load_balancer_ip = None;
    spec.load_balancer_source_ranges = None;
    spec.ports = None;
    // spec.publish_not_ready_addresses owns no heap allocations
    spec.selector = None;
    spec.session_affinity = None;
    spec.session_affinity_config = None;
    spec.type_ = None;
  }
  svc.status = None;
}

fn shrink_objectmeta_memory_usage(meta: &mut ObjectMeta) {
  meta.annotations = None;
  // meta.creation_timestamp owns no heap allocations
  // meta.deletion_grace_period_seconds owns no heap allocations
  // meta.deletion_timestamp owns no heap allocations
  meta.finalizers = None;
  meta.generate_name = None;
  // meta.generation owns no heap allocations
  // meta.labels is explicitly used
  meta.managed_fields = None;
  // meta.name is essential
  // meta.namespace is essential
  meta.owner_references = None;
  // meta.resource_version is probably essential
  meta.self_link = None;
  // meta.uid is essential
}

async fn advertise(routes: BTreeSet<String>) -> Result<(), Error> {
  let mut routes_str = String::new();
  for route in routes {
    if !routes_str.is_empty() {
      routes_str.push(',');
    }
    routes_str.push_str(&route);
  }
  let mut cmd = Command::new("tailscale");
  cmd.arg("set").arg("--advertise-routes").arg(routes_str);
  let cmd_str = format!("{:?}", cmd);
  log::debug!("subprocess invoke: {}", cmd_str);
  let status = cmd
    .status()
    .await
    .map_err(Error::exec_subprocess(&cmd_str))?;
  log::debug!("subprocess exit: {}", status);
  if !status.success() {
    return Err(Error::SubprocessStatus(cmd_str, status));
  }
  Ok(())
}

#[derive(Debug, Error)]
pub enum Error {
  #[error("failed to execute subprocess {0:?}: {1}")]
  ExecSubprocess(String, std::io::Error),
  #[error("failed to initialise kubernetes client: {0}")]
  KubeClient(kube::Error),
  #[error("failed to get in-cluster kubernetes client config: {0}")]
  KubeConfig(kube::config::InClusterError),
  #[error("failed to read environment variable {0}: {1}")]
  ReadEnv(&'static str, std::env::VarError),
  #[error("subprocess {0:?} exited with failure status {1}")]
  SubprocessStatus(String, std::process::ExitStatus),
}

impl Error {
  fn exec_subprocess(cmdline: impl Into<String>) -> impl FnOnce(std::io::Error) -> Self {
    move |cause| Self::ExecSubprocess(cmdline.into(), cause)
  }
  fn read_env(name: &'static str) -> impl FnOnce(std::env::VarError) -> Self {
    move |cause| Self::ReadEnv(name, cause)
  }
}

#[derive(Debug)]
struct MaybeChanged;
