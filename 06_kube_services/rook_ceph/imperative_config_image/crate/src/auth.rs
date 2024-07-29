use crate::error::Error;
use lazy_static::lazy_static;
use regex::Regex;
use std::collections::BTreeMap;
use std::ops::BitOr;
use std::process::{Command, Stdio};

pub fn configure() -> Result<(), Error> {
  let rbd_client_caps = Caps::for_user("client.csi-rbd-node").map_err(Error::with_context(
    "failed to get caps of client.csi-rbd-node",
  ))?;
  let cephfs_client_caps = Caps::for_user("client.csi-cephfs-node").map_err(
    Error::with_context("failed to get caps of client.csi-cephfs-node"),
  )?;
  let client_caps = &rbd_client_caps | &cephfs_client_caps;
  ensure_user_state_with_context("client.coloris", &client_caps)?;
  ensure_user_state_with_context("client.saelli", &client_caps)?;
  Ok(())
}

fn ensure_user_state_with_context(name: &str, caps: &Caps) -> Result<(), Error> {
  let context = format!("failed to manage user {}", name).leak();
  ensure_user_state(name, caps).map_err(Error::with_context(context))
}

fn ensure_user_state(name: &str, caps: &Caps) -> Result<(), Error> {
  let exists = user_exists(name).map_err(Error::with_context("failed to query if user exists"))?;
  if exists {
    log::info!("user {} already exists", name);
  } else {
    log::info!("creating user {}", name);
    create_user(name).map_err(Error::with_context("failed to create user"))?;
  }
  ensure_user_caps(name, caps).map_err(Error::with_context("failed to apply caps"))
}

fn user_exists(name: &str) -> Result<bool, Error> {
  const CMD: &'static str = "ceph auth get";
  let status = Command::new("ceph")
    .args(&["auth", "get", name])
    .stdin(Stdio::null())
    .stdout(Stdio::null())
    .stderr(Stdio::inherit())
    .status()
    .map_err(Error::exec_subprocess(CMD))?;
  if status.success() {
    Ok(true)
  } else if status.code() == Some(2) {
    // ENOENT
    Ok(false)
  } else {
    Err(Error::SubprocessStatus(CMD, status))
  }
}

fn create_user(name: &str) -> Result<(), Error> {
  const CMD: &'static str = "ceph auth add";
  let status = Command::new("ceph")
    .args(&["auth", "add", name])
    .stdin(Stdio::null())
    .stdout(Stdio::inherit())
    .stderr(Stdio::inherit())
    .status()
    .map_err(Error::exec_subprocess(CMD))?;
  if status.success() {
    Ok(())
  } else {
    Err(Error::SubprocessStatus(CMD, status))
  }
}

fn ensure_user_caps(name: &str, caps: &Caps) -> Result<(), Error> {
  const CMD: &'static str = "ceph auth caps";
  let status = Command::new("ceph")
    .args(&["auth", "caps", name])
    .args(caps.as_args())
    .stdin(Stdio::null())
    .stdout(Stdio::inherit())
    .stderr(Stdio::inherit())
    .status()
    .map_err(Error::exec_subprocess(CMD))?;
  if status.success() {
    Ok(())
  } else {
    Err(Error::SubprocessStatus(CMD, status))
  }
}

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
struct Caps(BTreeMap<&'static str, &'static str>);

impl Caps {
  fn for_user(name: &str) -> Result<Self, Error> {
    const CMD: &'static str = "ceph auth get";
    let out = Command::new("ceph")
      .args(&["auth", "get", name])
      .stdin(Stdio::null())
      .stdout(Stdio::piped())
      .stderr(Stdio::inherit())
      .output()
      .map_err(Error::exec_subprocess(CMD))?;
    if out.status.success() {
      let out = String::from_utf8(out.stdout).map_err(Error::Utf8)?.leak();
      Ok(Self::parse(out))
    } else {
      Err(Error::SubprocessStatus(CMD, out.status))
    }
  }
  fn parse(input: &'static str) -> Self {
    lazy_static! {
      static ref REGEX: Regex = Regex::new(r#"(?m)^\s*caps\s+(\S+)\s*=\s*"(.*)"\s*$"#).unwrap();
    }
    Self(
      REGEX
        .captures_iter(input)
        .map(|captures| {
          (
            captures.get(1).unwrap().as_str(),
            captures.get(2).unwrap().as_str(),
          )
        })
        .collect(),
    )
  }
  fn as_args(&self) -> impl Iterator<Item = &'static str> + '_ {
    self.0.iter().flat_map(|(&svc, &svc_caps)| [svc, svc_caps])
  }
}

impl<'a> BitOr for &'a Caps {
  type Output = Caps;
  fn bitor(self, other: &'a Caps) -> Caps {
    let mut result = BTreeMap::new();
    for (&svc, &self_svc_caps) in self.0.iter() {
      let svc_caps: &'static str = match other.0.get(svc) {
        Some(other_svc_caps) => format!("{}, {}", self_svc_caps, other_svc_caps).leak(),
        None => self_svc_caps,
      };
      result.insert(svc, svc_caps);
    }
    for (&svc, &other_svc_caps) in other.0.iter() {
      if !result.contains_key(svc) {
        result.insert(svc, other_svc_caps);
      }
    }
    Caps(result)
  }
}

#[cfg(test)]
mod tests {
  use super::Caps;

  #[test]
  fn test_caps_parse_rbd() {
    const INPUT: &'static str = r#"[client.csi-rbd-provisioner]
	key = REDACTED
	caps mgr = "allow rw"
	caps mon = "profile rbd, allow command 'osd blocklist'"
	caps osd = "profile rbd"
"#;
    let expected = Caps(
      [
        ("mgr", "allow rw"),
        ("mon", "profile rbd, allow command 'osd blocklist'"),
        ("osd", "profile rbd"),
      ]
      .into_iter()
      .collect(),
    );
    let got = Caps::parse(INPUT);
    assert_eq!(got, expected, "got {:#?}", got);
  }

  #[test]
  fn test_caps_parse_cephfs() {
    const INPUT: &'static str = r#"[client.csi-cephfs-provisioner]
	key = REDACTED
	caps mds = "allow *"
	caps mgr = "allow rw"
	caps mon = "allow r, allow command 'osd blocklist'"
	caps osd = "allow rw tag cephfs metadata=*"
"#;
    let expected = Caps(
      [
        ("mds", "allow *"),
        ("mgr", "allow rw"),
        ("mon", "allow r, allow command 'osd blocklist'"),
        ("osd", "allow rw tag cephfs metadata=*"),
      ]
      .into_iter()
      .collect(),
    );
    let got = Caps::parse(INPUT);
    assert_eq!(got, expected, "got {:#?}", got);
  }

  #[test]
  fn test_caps_union() {
    let input1 = Caps(
      [
        ("mgr", "allow rw"),
        ("mon", "profile rbd, allow command 'osd blocklist'"),
        ("osd", "profile rbd"),
      ]
      .into_iter()
      .collect(),
    );
    let input2 = Caps(
      [
        ("mds", "allow *"),
        ("mgr", "allow rw"),
        ("mon", "allow r, allow command 'osd blocklist'"),
        ("osd", "allow rw tag cephfs metadata=*"),
      ]
      .into_iter()
      .collect(),
    );
    let expected = Caps(
      [
        ("mds", "allow *"),
        ("mgr", "allow rw, allow rw"),
        (
          "mon",
          "profile rbd, allow command 'osd blocklist', allow r, allow command 'osd blocklist'",
        ),
        ("osd", "profile rbd, allow rw tag cephfs metadata=*"),
      ]
      .into_iter()
      .collect(),
    );
    let got = &input1 | &input2;
    assert_eq!(got, expected, "got {:#?}", got);
  }
}
