use crate::error::Error;
use crate::util::{
  MaybeReady::{self, NotReady, Ready},
  Never,
};
use cidr::IpCidr;
use serde::Serialize;
use std::collections::BTreeSet;
use tokio::sync::watch;

pub async fn manage(
  mut pod_cidrs: watch::Receiver<MaybeReady<BTreeSet<IpCidr>>>,
) -> Result<Never, Error> {
  loop {
    if let Err(err) = manage_once(&mut pod_cidrs).await {
      log::error!("{}", err);
    }
    if pod_cidrs.changed().await.is_err() {
      break Err(Error::channel_closed("pod_cidrs"));
    }
  }
}

async fn manage_once(
  pod_cidrs: &mut watch::Receiver<MaybeReady<BTreeSet<IpCidr>>>,
) -> Result<(), Error> {
  let ranges = {
    let guard = pod_cidrs.borrow_and_update();
    log::trace!("pod_cidrs = {:?}", *guard);
    match *guard {
      Ready(ref set) => pod_cidrs_to_ranges(set),
      NotReady => return Ok(()),
    }
  };

  let content = serde_json::to_string(&Config {
    cni_version: "1.0.0",
    name: "skaia-cni",
    plugins: [Plugin::Bridge {
      is_default_gateway: true,
      ip_masq: false,
      ipam: IPAMPlugin::HostLocal { ranges },
    }],
  })
  .map_err(Error::serialize_json)?;
  log::trace!("content: {}", content);

  const PATH: &'static str = "/cni-config/10-skaia-cni.conflist";
  tokio::fs::write(PATH, content)
    .await
    .map_err(Error::write_file(PATH))?;
  log::info!("wrote {}", PATH);
  Ok(())
}

fn pod_cidrs_to_ranges(pod_cidrs: &BTreeSet<IpCidr>) -> [Vec<Range>; 2] {
  let mut ipv4_ranges = Vec::new();
  let mut ipv6_ranges = Vec::new();
  for &pod_cidr in pod_cidrs {
    let vec = match pod_cidr {
      IpCidr::V4(_) => &mut ipv4_ranges,
      IpCidr::V6(_) => &mut ipv6_ranges,
    };
    vec.push(Range {
      subnet: format!("{:#}", pod_cidr),
    });
  }
  [ipv4_ranges, ipv6_ranges]
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct Config {
  cni_version: &'static str,
  name: &'static str,
  plugins: [Plugin; 1],
}

#[derive(Debug, Serialize)]
#[serde(tag = "type", rename_all = "kebab-case")]
enum Plugin {
  #[serde(rename_all = "camelCase")]
  Bridge {
    is_default_gateway: bool,
    ip_masq: bool,
    ipam: IPAMPlugin,
  },
}

#[derive(Debug, Serialize)]
#[serde(tag = "type", rename_all = "kebab-case")]
enum IPAMPlugin {
  #[serde(rename_all = "camelCase")]
  HostLocal { ranges: [Vec<Range>; 2] },
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct Range {
  subnet: String,
}
