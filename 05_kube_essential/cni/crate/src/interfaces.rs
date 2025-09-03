// TODO: is it possible to do this without polling? e.g. netlink?

use crate::error::Error;
use crate::util::{MaybeReady, Never};
use cidr::{Ipv4Inet, Ipv6Inet};
use std::collections::{BTreeMap, BTreeSet};
use std::hash::{BuildHasher, RandomState};
use std::time::Duration;
use tokio::{sync::watch, time::sleep};

pub async fn watch(
  channel: watch::Sender<MaybeReady<BTreeMap<InterfaceName, Interface>>>,
) -> Result<Never, Never> {
  let hasher = RandomState::new();
  loop {
    if let Err(err) = poll(&channel, &hasher).await {
      log::error!("{}", err);
    }
    sleep(Duration::from_secs(30)).await;
  }
}

async fn poll(
  channel: &watch::Sender<MaybeReady<BTreeMap<InterfaceName, Interface>>>,
  hasher: &RandomState,
) -> Result<(), Error> {
  let ipas_ifaces = ipas::poll().await.map_err(Error::context("ipas::poll"))?;
  let sysfs_data = sysfs::poll().await.map_err(Error::context("sysfs::poll"))?;
  let ifaces = ipas_ifaces.into_iter().filter_map(|ipas_iface| {
    if sysfs_data.hw_iface_names.contains(&ipas_iface.ifname) {
      Some((ipas_iface.ifname, Interface::new(ipas_iface.addr_info)))
    } else {
      None
    }
  });

  channel.send_if_modified(|mr| {
    let hash_before = hasher.hash_one(&*mr);
    {
      let map = mr.insert_default_if_not_ready();
      map.clear();
      map.extend(ifaces);
    }
    let changed = hasher.hash_one(&*mr) != hash_before;
    if changed {
      log::trace!("sending interfaces = {:?}", mr);
    }
    changed
  });
  Ok(())
}

pub type InterfaceName = String;

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub struct Interface {
  pub v4addrs: BTreeSet<Ipv4Inet>,
  pub v6addrs: BTreeSet<Ipv6Inet>,
}

impl Interface {
  fn new(addr_infos: Vec<ipas::AddrInfo>) -> Self {
    let mut v4addrs = BTreeSet::new();
    let mut v6addrs = BTreeSet::new();
    for addr_info in addr_infos {
      match addr_info {
        ipas::AddrInfo::V4(addr_info) => {
          v4addrs.insert(Ipv4Inet::new(addr_info.local, addr_info.prefixlen).unwrap());
        }
        ipas::AddrInfo::V6(addr_info) => {
          v6addrs.insert(Ipv6Inet::new(addr_info.local, addr_info.prefixlen).unwrap());
        }
      }
    }
    Self { v4addrs, v6addrs }
  }
}

mod ipas {
  use crate::error::Error;
  use serde::Deserialize;
  use std::net::{Ipv4Addr, Ipv6Addr};
  use tokio::process::Command;

  pub async fn poll() -> Result<Vec<Interface>, Error> {
    let mut cmd = Command::new("ip");
    cmd.arg("-json").arg("addr").arg("show");
    let cmd_str = format!("{:?}", cmd.as_std());
    log::debug!("subprocess invoke: {}", cmd_str);
    let output = cmd
      .output()
      .await
      .map_err(Error::subprocess_exec(&cmd_str))?;
    log::debug!("subprocess exit: {}", output.status);
    if !output.status.success() {
      return Err(Error::subprocess_status(&cmd_str, output.status));
    }
    serde_json::from_slice(&output.stdout).map_err(Error::deserialize_json)
  }

  #[derive(Clone, Debug, Deserialize)]
  pub struct Interface {
    pub ifname: String,
    pub addr_info: Vec<AddrInfo>,
  }

  #[derive(Clone, Copy, Debug, Deserialize)]
  #[serde(tag = "family")]
  pub enum AddrInfo {
    #[serde(rename = "inet")]
    V4(V4AddrInfo),
    #[serde(rename = "inet6")]
    V6(V6AddrInfo),
  }

  #[derive(Clone, Copy, Debug, Deserialize)]
  pub struct V4AddrInfo {
    pub local: Ipv4Addr,
    pub prefixlen: u8,
  }

  #[derive(Clone, Copy, Debug, Deserialize)]
  pub struct V6AddrInfo {
    pub local: Ipv6Addr,
    pub prefixlen: u8,
  }
}

mod sysfs {
  use crate::error::Error;
  use std::collections::HashSet;
  use std::io::ErrorKind::{NotADirectory, NotFound};
  use tokio::fs::{metadata, read_dir};

  pub async fn poll() -> Result<Data, Error> {
    const DIR: &'static str = "/sys/class/net";
    let mut iface_entries = read_dir(DIR).await.map_err(Error::read_dir(DIR))?;
    let mut hw_iface_names = HashSet::new();
    while let Some(iface_entry) = iface_entries
      .next_entry()
      .await
      .map_err(Error::read_dir(DIR))?
    {
      let mut device_symlink = iface_entry.path();
      device_symlink.push("device");
      match metadata(&device_symlink).await {
        Ok(_) => {
          hw_iface_names.insert(
            iface_entry
              .file_name()
              .into_string()
              .expect("/sys/class/net contains directory entry with non-UTF8 name"),
          );
        }
        Err(err) if matches!(err.kind(), NotFound | NotADirectory) => {}
        Err(err) => return Err(Error::stat(device_symlink, err)),
      }
    }
    Ok(Data { hw_iface_names })
  }

  #[derive(Clone, Debug)]
  pub struct Data {
    pub hw_iface_names: HashSet<String>,
  }
}
