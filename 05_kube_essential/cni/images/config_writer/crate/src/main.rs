use self::util::DedupAdjacentStreamExt;
use futures_util::{
  future::{ready, TryFutureExt},
  pin_mut,
  stream::{FusedStream, StreamExt},
};
use k8s_openapi::api::core::v1::Node;
use kube::{
  runtime::{watcher, WatchStreamExt},
  Api,
};
use serde::Serialize;
use std::path::Path;
use std::process::ExitCode;
use thiserror::Error;

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
  let pod_cidrs_st = watch_pod_cidrs(init_kube_client()?, &this_node_name);
  pin_mut!(pod_cidrs_st);
  loop {
    let pod_cidrs = pod_cidrs_st.next().await.unwrap();
    log::info!("pod_cidrs = {:?}", pod_cidrs);
    if !pod_cidrs.is_empty() {
      if let Err(err) = write_config(pod_cidrs).await {
        log::error!("failed to write config: {}", err);
      }
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

fn watch_pod_cidrs(
  kube_client: kube::Client,
  node_name: &str,
) -> impl FusedStream<Item = Vec<String>> + Send + '_ {
  watch_node(kube_client, node_name)
    .map(|node| {
      let mut pod_cidrs = node.spec.unwrap().pod_cidrs.unwrap_or_else(Vec::new);
      pod_cidrs.sort_unstable();
      pod_cidrs
    })
    .dedup_adjacent()
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

async fn write_config(pod_cidrs: Vec<String>) -> Result<(), Error> {
  let path = Path::new("/dest/10-skaia-cni.conflist");
  log::info!("writing {}", path.display());
  let content = generate_config(pod_cidrs)?;
  tokio::fs::write(path, content)
    .map_err(Error::write_file(path))
    .await
}

fn generate_config(pod_cidrs: Vec<String>) -> Result<String, Error> {
  use cidr::IpCidr;
  use std::str::FromStr;
  let mut ipv4_ranges = Vec::new();
  let mut ipv6_ranges = Vec::new();
  for pod_cidr in pod_cidrs.iter() {
    match IpCidr::from_str(pod_cidr) {
      Ok(IpCidr::V4(_)) => ipv4_ranges.push(Range { subnet: pod_cidr }),
      Ok(IpCidr::V6(_)) => ipv6_ranges.push(Range { subnet: pod_cidr }),
      Err(err) => log::warn!(
        "an element of Node.spec.podCidrs ({:?}) couldn't be parsed as a CIDR: {}",
        pod_cidr,
        err
      ),
    }
  }
  let content = serde_json::to_string(&Config {
    cni_version: "1.0.0",
    name: "skaia-cni",
    plugins: &[Plugin::Bridge {
      is_default_gateway: true,
      ip_masq: true,
      // It would be nice to use "nftables", but that relies on the "nft"
      // executable being present on $PATH in the Talos environment, which
      // it currently is not. Fixing this requires writing a Talos extension
      // (overkill), or hoping it gets added to Talos as standard in a future
      // version.
      ip_masq_backend: "iptables",
      ipam: IPAMPlugin::HostLocal {
        ranges: &[&ipv4_ranges, &ipv6_ranges],
      },
    }],
  })
  .map_err(Error::SerializeJSON)?;
  log::debug!("generated cni config: {}", content);
  Ok(content)
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct Config<'a> {
  cni_version: &'a str,
  name: &'a str,
  plugins: &'a [Plugin<'a>],
}

#[derive(Debug, Serialize)]
#[serde(tag = "type", rename_all = "kebab-case")]
enum Plugin<'a> {
  #[serde(rename_all = "camelCase")]
  Bridge {
    is_default_gateway: bool,
    ip_masq: bool,
    ip_masq_backend: &'a str,
    ipam: IPAMPlugin<'a>,
  },
}

#[derive(Debug, Serialize)]
#[serde(tag = "type", rename_all = "kebab-case")]
enum IPAMPlugin<'a> {
  #[serde(rename_all = "camelCase")]
  HostLocal { ranges: &'a [&'a [Range<'a>]] },
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct Range<'a> {
  subnet: &'a str,
}

#[derive(Debug, Error)]
enum Error {
  #[error("failed to initialise kubernetes client: {0}")]
  KubeClient(kube::Error),
  #[error("failed to get in-cluster kubernetes client config: {0}")]
  KubeConfig(kube::config::InClusterError),
  #[error("failed to read environment variable {0}: {1}")]
  ReadEnv(&'static str, std::env::VarError),
  #[error("failed to serialize JSON: {0}")]
  SerializeJSON(serde_json::Error),
  #[error("failed to write {0}: {1}")]
  WriteFile(&'static Path, std::io::Error),
}

impl Error {
  fn read_env(name: &'static str) -> impl FnOnce(std::env::VarError) -> Self {
    move |cause| Self::ReadEnv(name, cause)
  }
  fn write_file(path: &'static Path) -> impl FnOnce(std::io::Error) -> Self {
    move |cause| Self::WriteFile(path, cause)
  }
}
