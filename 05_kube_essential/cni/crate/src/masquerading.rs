use crate::error::Error;
use crate::interfaces::{Interface, InterfaceName};
use crate::util::{
  MaybeReady::{self, NotReady, Ready},
  Never,
};
use cidr::Inet;
use std::collections::{BTreeMap, BTreeSet};
use std::fmt::Write;
use std::process::Stdio;
use tokio::io::AsyncWriteExt;
use tokio::process::Command;
use tokio::sync::watch;

pub async fn manage(
  mut interfaces: watch::Receiver<MaybeReady<BTreeMap<InterfaceName, Interface>>>,
) -> Result<Never, Error> {
  loop {
    if let Err(err) = manage_once(&mut interfaces).await {
      log::error!("{}", err);
    }
    if interfaces.changed().await.is_err() {
      break Err(Error::channel_closed("interfaces"));
    }
  }
}

async fn manage_once(
  interfaces: &mut watch::Receiver<MaybeReady<BTreeMap<InterfaceName, Interface>>>,
) -> Result<(), Error> {
  let script = {
    let guard = interfaces.borrow_and_update();
    log::trace!("interfaces = {:?}", *guard);
    match *guard {
      Ready(ref map) => generate_script(map),
      NotReady => return Ok(()),
    }
  };
  log::trace!("nftables script:\n{}", script);

  let mut cmd = Command::new("nft");
  cmd.arg("--file").arg("/dev/stdin").stdin(Stdio::piped());
  let cmd_str = format!("{:?}", cmd.as_std());
  log::debug!("subprocess invoke: {}", cmd_str);
  let mut process = cmd.spawn().map_err(Error::subprocess_exec(&cmd_str))?;
  process
    .stdin
    .as_mut()
    .unwrap()
    .write_all(script.as_bytes())
    .await
    .map_err(Error::write_subprocess_stdin(&cmd_str))?;
  let status = process
    .wait()
    .await
    .map_err(Error::subprocess_wait(&cmd_str))?;
  log::debug!("subprocess exit: {}", status);
  if !status.success() {
    return Err(Error::subprocess_status(&cmd_str, status));
  }
  Ok(())
}

fn generate_script(interfaces: &BTreeMap<InterfaceName, Interface>) -> String {
  fn per_family<I: Inet>(
    s: &mut String,
    interfaces: &BTreeMap<InterfaceName, Interface>,
    family_name: &'static str,
    get_family_addrs: impl for<'a> Fn(&'a Interface) -> &'a BTreeSet<I>,
  ) {
    const TABLE_NAME: &'static str = "skaia-masq";
    write!(
      s,
      "table {} {}\nflush table {} {}\ntable {} {} {{\n",
      family_name, TABLE_NAME, family_name, TABLE_NAME, family_name, TABLE_NAME
    )
    .unwrap();
    s.push_str("  chain postrouting {\n");
    s.push_str("    type nat hook postrouting priority srcnat; policy accept;\n");
    for iface_name in interfaces.keys() {
      write!(
        s,
        "    oif \"{}\" jump postrouting/{}\n",
        iface_name, iface_name
      )
      .unwrap();
    }
    s.push_str("  }\n");
    for (iface_name, iface) in interfaces.iter() {
      write!(s, "  chain postrouting/{} {{\n", iface_name).unwrap();
      for &addr in (get_family_addrs)(iface) {
        write!(s, "    {} saddr {} accept\n", family_name, addr.network()).unwrap();
      }
      s.push_str("    masquerade\n");
      s.push_str("  }\n");
    }
    s.push_str("}\n");
  }

  let mut s = String::with_capacity(4096);
  per_family(&mut s, interfaces, "ip", |i| &i.v4addrs);
  per_family(&mut s, interfaces, "ip6", |i| &i.v6addrs);
  s
}
