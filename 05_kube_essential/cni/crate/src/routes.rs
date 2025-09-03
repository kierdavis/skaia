use crate::error::Error;
use crate::util::{
  MaybeReady::{self, NotReady, Ready},
  Never,
};
use cidr::IpCidr;
use futures_util::{FutureExt, select};
use k8s_openapi::api::{
  core::v1::Service,
  discovery::v1::{Endpoint, EndpointSlice},
};
use kube::runtime::reflector;
use std::collections::BTreeSet;
use std::net::IpAddr;
use std::str::FromStr;
use tokio::{process::Command, sync::watch};

pub async fn advertise(
  mut pod_cidrs: watch::Receiver<MaybeReady<BTreeSet<IpCidr>>>,
  service_cidrs: &'static [IpCidr],
  mut endpoint_slices: watch::Receiver<MaybeReady<reflector::Store<EndpointSlice>>>,
  mut services: watch::Receiver<MaybeReady<reflector::Store<Service>>>,
  node_name: &'static str,
) -> Result<Never, Error> {
  loop {
    if let Err(err) = advertise_once(
      &mut pod_cidrs,
      service_cidrs,
      &mut endpoint_slices,
      &mut services,
      node_name,
    )
    .await
    {
      log::error!("{}", err);
    }
    select! {
      result = pod_cidrs.changed().fuse() => if result.is_err() {
        break Err(Error::channel_closed("pod_cidrs"));
      },
      result = endpoint_slices.changed().fuse() => if result.is_err() {
        break Err(Error::channel_closed("endpoint_slices"));
      },
      result = services.changed().fuse() => if result.is_err() {
        break Err(Error::channel_closed("services"));
      },
    }
  }
}

async fn advertise_once(
  pod_cidrs: &mut watch::Receiver<MaybeReady<BTreeSet<IpCidr>>>,
  service_cidrs: &[IpCidr],
  endpoint_slices: &mut watch::Receiver<MaybeReady<reflector::Store<EndpointSlice>>>,
  services: &mut watch::Receiver<MaybeReady<reflector::Store<Service>>>,
  node_name: &str,
) -> Result<(), Error> {
  let (pod_cidrs, endpoint_slices, services) = {
    let pc_guard = pod_cidrs.borrow_and_update();
    let es_guard = endpoint_slices.borrow_and_update();
    let s_guard = services.borrow_and_update();
    fn abbrev<T>(val: &MaybeReady<T>) -> &'static str {
      match *val {
        NotReady => "NotReady",
        Ready(_) => "Ready",
      }
    }
    log::trace!(
      "pod_cidrs = {:?}, endpoint_slices = {}, services = {}",
      *pc_guard,
      abbrev(&es_guard),
      abbrev(&s_guard)
    );
    match (&*pc_guard, &*es_guard, &*s_guard) {
      (&Ready(ref pc), &Ready(ref es), &Ready(ref s)) => (pc.clone(), es.clone(), s.clone()),
      _ => return Ok(()),
    }
  };

  let mut routes = pod_cidrs;
  routes.extend(service_cidrs);
  compute_service_endpoint_routes(&mut routes, &endpoint_slices, &services, node_name);

  tailscale_advertise(routes).await
}

fn compute_service_endpoint_routes(
  dest: &mut BTreeSet<IpCidr>,
  endpoint_slices: &reflector::Store<EndpointSlice>,
  services: &reflector::Store<Service>,
  node_name: &str,
) {
  fn endpoint_is_ready(ep: &Endpoint) -> bool {
    match ep.conditions {
      Some(ref conds) => conds.ready.unwrap_or(true),
      None => true,
    }
  }
  fn endpoint_node_name_equals(ep: &Endpoint, expected: &str) -> bool {
    match ep.node_name {
      Some(ref val) => val == expected,
      None => false,
    }
  }
  for eps in endpoint_slices.state() {
    let ns = eps.metadata.namespace.as_ref().unwrap();
    let eps_name = eps.metadata.name.as_ref().unwrap();
    let has_ep_on_this_node = eps
      .endpoints
      .iter()
      .any(|ep| endpoint_is_ready(ep) && endpoint_node_name_equals(ep, node_name));
    let has_ep_on_any_node = eps
      .endpoints
      .iter()
      .any(|ep| endpoint_is_ready(ep) && ep.node_name.is_some());
    let should_advertise = has_ep_on_this_node || !has_ep_on_any_node;
    if !should_advertise {
      log::trace!(
        "EndpointSlice {}/{} skipped (no endpoint on this node)",
        ns,
        eps_name
      );
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
          "EndpointSlice {}/{} skipped (no {} label)",
          ns,
          eps_name,
          LABEL
        );
        continue;
      }
    };
    let svc_ref = reflector::ObjectRef::new(svc_name).within(ns);
    let svc = match services.get(&svc_ref) {
      Some(x) => x,
      None => {
        log::warn!(
          "EndpointSlice {}/{} skipped (no data available for Service {}/{})",
          ns,
          eps_name,
          ns,
          svc_name
        );
        continue;
      }
    };
    dest.extend(
      svc
        .spec
        .as_ref()
        .unwrap()
        .cluster_ips
        .as_ref()
        .map_or(&[] as &[_], Vec::as_slice)
        .iter()
        .filter(|&addr_str| addr_str != "None")
        .filter_map(|addr_str| match IpAddr::from_str(addr_str) {
          Ok(addr) => Some(addr),
          Err(err) => {
            log::warn!(
              "EndpointSlice {}/{}: service clusterIP {:?} skipped (parse error: {})",
              ns,
              eps_name,
              addr_str,
              err
            );
            None
          }
        })
        .map(IpCidr::new_host)
        .inspect(|cidr| log::trace!("EndpointSlice {}/{} => {}", ns, eps_name, cidr)),
    );
  }
}

async fn tailscale_advertise(routes: BTreeSet<IpCidr>) -> Result<(), Error> {
  log::info!("advertising routes: {:?}", routes);

  use std::fmt::Write;
  let mut routes_str = String::new();
  for route in routes {
    if !routes_str.is_empty() {
      routes_str.push(',');
    }
    write!(routes_str, "{:#}", route).unwrap();
  }

  let mut cmd = Command::new("tailscale");
  cmd.arg("set").arg("--advertise-routes").arg(&routes_str);
  let cmd_str = format!("{:?}", cmd.as_std());
  log::debug!("subprocess invoke: {}", cmd_str);
  let status = cmd
    .status()
    .await
    .map_err(Error::subprocess_exec(&cmd_str))?;
  log::debug!("subprocess exit: {}", status);
  if !status.success() {
    return Err(Error::subprocess_status(&cmd_str, status));
  }
  Ok(())
}
