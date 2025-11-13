mod cni_config;
mod cni_plugins;
mod error;
mod interfaces;
mod kubernetes;
mod masquerading;
mod routes;
mod util;

use crate::error::Error;
use crate::util::{MaybeReady::NotReady, Never};
use cidr::IpCidr;
use futures_util::{FutureExt, select};
use std::path::Path;
use std::process::ExitCode;
use std::str::FromStr;
use tokio::sync::watch;

fn main() -> ExitCode {
  env_logger::init();
  let Err(err) = app();
  log::error!("{}", err);
  try_write_termination_log(&err);
  ExitCode::FAILURE
}

fn try_write_termination_log(msg: &impl std::fmt::Display) {
  use std::io::Write;
  const PATH: &'static str = "/dev/termination-log";
  if let Err(err) = std::fs::File::create(PATH).and_then(move |mut f| write!(f, "{}", msg)) {
    log::warn!("failed to write {}: {}", PATH, err);
  }
}

#[tokio::main(flavor = "current_thread")]
async fn app() -> Result<Never, Error> {
  let node_name = get_node_name()?;
  let service_cidrs = get_service_cidrs()?;
  let cni_plugins_src = get_cni_plugins_src()?;
  let cni_plugins_dest = get_cni_plugins_dest()?;
  let kube = crate::kubernetes::Client::new()?;

  let (pod_cidrs_tx, pod_cidrs_rx) = watch::channel(NotReady);
  let (endpoint_slices_tx, endpoint_slices_rx) = watch::channel(NotReady);
  let (services_tx, services_rx) = watch::channel(NotReady);
  let (interfaces_tx, interfaces_rx) = watch::channel(NotReady);

  macro_rules! select_tasks {
    ($($name:literal = $fut:expr;)*) => {
      select! {
        $(
          result = tokio::spawn($fut).fuse() => {
            result.map_err(Error::task_terminated($name))?.map_err(Error::from)
          }
        )*
      }
    };
  }
  select_tasks! {
    "kubernetes::watch_node" = kube.watch_node(node_name, pod_cidrs_tx);
    "kubernetes::watch_resource_set<EndpointSlice>" = kube.watch_resource_set(endpoint_slices_tx);
    "kubernetes::watch_resource_set<Service>" = kube.watch_resource_set(services_tx);
    "interfaces::watch" = crate::interfaces::watch(interfaces_tx);
    "cni_plugins::install" = crate::cni_plugins::install_then_sleep(cni_plugins_src, cni_plugins_dest);
    "cni_config::manage" = crate::cni_config::manage(pod_cidrs_rx.clone());
    "masquerading::manage" = crate::masquerading::manage(interfaces_rx);
    "routes::advertise" = crate::routes::advertise(
      pod_cidrs_rx,
      service_cidrs,
      endpoint_slices_rx,
      services_rx,
      node_name,
    );
  }
}

fn get_node_name() -> Result<&'static str, Error> {
  const VAR: &'static str = "NODE_NAME";
  let val = std::env::var(VAR).map_err(Error::get_env(VAR))?.leak();
  log::trace!("NODE_NAME = {}", val);
  Ok(val)
}

fn get_service_cidrs() -> Result<&'static [IpCidr], Error> {
  const VAR: &'static str = "SERVICE_CIDRS";
  let val = std::env::var(VAR)
    .map_err(Error::get_env(VAR))?
    .leak()
    .split(',')
    .map(|s| IpCidr::from_str(s).map_err(Error::parse_service_cidr(s)))
    .collect::<Result<Vec<_>, _>>()?
    .leak();
  log::trace!("SERVICE_CIDRS = {:?}", val);
  Ok(val)
}

fn get_cni_plugins_src() -> Result<&'static Path, Error> {
  const VAR: &'static str = "CNI_PLUGINS_SRC";
  let val = Path::new(
    std::env::var_os(VAR)
      .ok_or(std::env::VarError::NotPresent)
      .map_err(Error::get_env(VAR))?
      .leak(),
  );
  log::trace!("CNI_PLUGINS_SRC = {}", val.display());
  Ok(val)
}

fn get_cni_plugins_dest() -> Result<&'static Path, Error> {
  const VAR: &'static str = "CNI_PLUGINS_DEST";
  let val = Path::new(
    std::env::var_os(VAR)
      .ok_or(std::env::VarError::NotPresent)
      .map_err(Error::get_env(VAR))?
      .leak(),
  );
  log::trace!("CNI_PLUGINS_DEST = {}", val.display());
  Ok(val)
}
