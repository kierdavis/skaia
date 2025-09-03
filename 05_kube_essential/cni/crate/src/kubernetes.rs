use crate::error::Error;
use crate::util::{
  MaybeReady::{self, NotReady, Ready},
  Never,
};
use cidr::IpCidr;
use futures_util::{FutureExt, StreamExt};
use k8s_openapi::{
  api::core::v1::{Node, Service, ServiceSpec},
  api::discovery::v1::{Endpoint, EndpointSlice},
  apimachinery::pkg::apis::meta::v1::ObjectMeta,
};
use kube::{
  Api,
  runtime::{WatchStreamExt, reflector, watcher},
};
use std::collections::BTreeSet;
use std::fmt::Debug;
use std::future::ready;
use std::hash::{BuildHasher, RandomState};
use std::str::FromStr;
use tokio::sync::watch;

pub struct Client(kube::Client);

impl Client {
  pub fn new() -> Result<Self, Error> {
    let cfg = kube::Config::incluster()?;
    let client = kube::Client::try_from(cfg).map_err(Error::kube_client)?;
    Ok(Self(client))
  }

  pub fn watch_node(
    &self,
    node_name: &'static str,
    pod_cidrs: watch::Sender<MaybeReady<BTreeSet<IpCidr>>>,
  ) -> impl Future<Output = Result<Never, Error>> + Send + 'static {
    let hasher = RandomState::new();
    watcher(Api::<Node>::all(self.0.clone()), watcher::Config::default())
      .default_backoff()
      .applied_objects()
      .filter_map(|result| {
        ready(match result {
          Ok(object) => Some(object),
          Err(err) => {
            log::warn!("watch_node: failed (will back off and retry): {}", err);
            None
          }
        })
      })
      .filter(move |object| {
        ready(match object.metadata.name {
          Some(ref name) => name == node_name,
          None => false,
        })
      })
      .inspect(|_| log::trace!("watch_node: detected change"))
      .for_each(move |object| {
        ready({
          let new_pod_cidrs = object
            .spec
            .and_then(|spec| spec.pod_cidrs)
            .unwrap_or_else(Vec::new)
            .into_iter()
            .filter_map(|s| match IpCidr::from_str(&s) {
              Ok(c) => Some(c),
              Err(err) => {
                log::warn!("watch_node: failed to parse pod_cidr {:?}: {}", s, err);
                None
              }
            });
          pod_cidrs.send_if_modified(|mr| {
            let hash_before = hasher.hash_one(&*mr);
            {
              let set = mr.insert_default_if_not_ready();
              set.clear();
              set.extend(new_pod_cidrs);
            }
            let changed = hasher.hash_one(&*mr) != hash_before;
            if changed {
              log::trace!("watch_node: sending pod_cidrs = {:?}", mr);
            }
            changed
          });
        })
      })
      .map(|()| Err(Error::kube_event_stream_terminated()))
  }

  pub fn watch_resource_set<K>(
    &self,
    out: watch::Sender<MaybeReady<reflector::Store<K>>>,
  ) -> impl Future<Output = Result<Never, Error>> + Send + 'static
  where
    K: Clone
      + Debug
      + serde::de::DeserializeOwned
      + DropUnusedFields
      + kube::Resource<DynamicType = ()>
      + Send
      + Sync
      + 'static,
  {
    use watcher::Event::*;
    let (store, store_writer) = reflector::store();
    let events = watcher(Api::all(self.0.clone()), watcher::Config::default())
      .default_backoff()
      .modify(K::drop_unused_fields);
    reflector(store_writer, events)
      .for_each(move |result| {
        ready(match result {
          Ok(Apply(object)) => {
            log::trace!(
              "watch_resource_set<{}>: {}/{} changed",
              K::kind(&()),
              object
                .meta()
                .namespace
                .as_ref()
                .map(String::as_str)
                .unwrap_or_default(),
              object
                .meta()
                .name
                .as_ref()
                .map(String::as_str)
                .unwrap_or_default(),
            );
            let _ = out.send(Ready(store.clone()));
          }
          Ok(Delete(object)) => {
            log::trace!(
              "watch_resource_set<{}>: {}/{} deleted",
              K::kind(&()),
              object
                .meta()
                .namespace
                .as_ref()
                .map(String::as_str)
                .unwrap_or_default(),
              object
                .meta()
                .name
                .as_ref()
                .map(String::as_str)
                .unwrap_or_default(),
            );
            let _ = out.send(Ready(store.clone()));
          }
          Ok(Init) => {
            log::trace!(
              "watch_resource_set<{}>: event stream (re)started, catching up...",
              K::kind(&())
            );
            let _ = out.send(NotReady);
          }
          Ok(InitApply(_)) => {}
          Ok(InitDone) => {
            log::trace!(
              "watch_resource_set<{}>: event stream caught up",
              K::kind(&())
            );
            let _ = out.send(Ready(store.clone()));
          }
          Err(err) => {
            log::warn!(
              "watch_resource_set<{}>: failed (will back off and retry): {}",
              K::kind(&()),
              err
            );
            let _ = out.send(NotReady);
          }
        })
      })
      .map(|()| Err(Error::kube_event_stream_terminated()))
  }
}

pub trait DropUnusedFields {
  fn drop_unused_fields(&mut self);
}

impl DropUnusedFields for Endpoint {
  fn drop_unused_fields(&mut self) {
    self.addresses = Vec::new();
    // self.conditions owns no heap allocations
    self.deprecated_topology = None;
    self.hints = None;
    self.hostname = None;
    // self.node_name is explicitly used
    self.target_ref = None;
    self.zone = None;
  }
}

impl DropUnusedFields for EndpointSlice {
  fn drop_unused_fields(&mut self) {
    self.address_type = String::new();
    self
      .endpoints
      .iter_mut()
      .for_each(Endpoint::drop_unused_fields);
    self.metadata.drop_unused_fields();
    self.ports = None;
  }
}

impl DropUnusedFields for ObjectMeta {
  fn drop_unused_fields(&mut self) {
    self.annotations = None;
    // self.creation_timestamp owns no heap allocations
    // self.deletion_grace_period_seconds owns no heap allocations
    // self.deletion_timestamp owns no heap allocations
    self.finalizers = None;
    self.generate_name = None;
    // self.generation owns no heap allocations
    // self.labels is explicitly used
    self.managed_fields = None;
    // self.name is essential
    // self.namespace is essential
    self.owner_references = None;
    // self.resource_version is probably essential
    self.self_link = None;
    // self.uid is essential
  }
}

impl DropUnusedFields for Service {
  fn drop_unused_fields(&mut self) {
    self.metadata.drop_unused_fields();
    self.spec.as_mut().map(ServiceSpec::drop_unused_fields);
    self.status = None;
  }
}

impl DropUnusedFields for ServiceSpec {
  fn drop_unused_fields(&mut self) {
    // self.allocate_load_balancer_node_ports owns no heap allocations
    self.cluster_ip = None;
    // self.cluster_ips is explicitly used
    self.external_ips = None;
    self.external_name = None;
    self.external_traffic_policy = None;
    // self.health_check_node_port owns no heap allocations
    self.internal_traffic_policy = None;
    self.ip_families = None;
    self.ip_family_policy = None;
    self.load_balancer_class = None;
    self.load_balancer_ip = None;
    self.load_balancer_source_ranges = None;
    self.ports = None;
    // self.publish_not_ready_addresses owns no heap allocations
    self.selector = None;
    self.session_affinity = None;
    self.session_affinity_config = None;
    self.type_ = None;
  }
}
