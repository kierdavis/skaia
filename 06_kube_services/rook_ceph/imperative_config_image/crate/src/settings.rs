use crate::error::Error;
use std::process::{Command, Stdio};

pub fn configure() -> Result<(), Error> {
  Namespace::Global.ensure_with_context("bluestore_compression_mode", "aggressive")?;
  Namespace::Global.ensure_with_context("osd_pool_default_size", "2")?;
  Namespace::Global.ensure_with_context("osd_scrub_max_interval", "3024000.000000")?;
  Namespace::Global.ensure_with_context("osd_scrub_min_interval", "1814400.000000")?;
  Namespace::Pool(".mgr").ensure_with_context("crush_rule", "skaia_gp0")?;
  Ok(())
}

#[derive(Clone, Copy, Debug)]
enum Namespace {
  Global,
  Pool(&'static str),
}

impl Namespace {
  fn ensure_with_context(self, key: &str, value: &str) -> Result<(), Error> {
    let context = format!("failed to ensure {}={} on {:?}", key, value, self).leak();
    self.ensure(key, value).map_err(Error::with_context(context))
  }

  fn ensure(self, key: &str, desired_value: &str) -> Result<(), Error> {
    let current_value = self.get(key)?;
    if current_value == desired_value {
      log::info!("{:?} {} already equals {}", self, key, desired_value);
      Ok(())
    } else {
      log::info!(
        "changing {:?} {} from {} to {}",
        self,
        key,
        current_value,
        desired_value
      );
      self.set(key, desired_value)
    }
  }

  fn get(self, key: &str) -> Result<String, Error> {
    let (ns_args, cmd_label) = match self {
      Self::Global => (vec!["config", "show", "mgr.a"], "ceph config show mgr.a"),
      Self::Pool(pool) => (vec!["osd", "pool", "get", pool], "ceph osd pool get"),
    };
    let out = Command::new("ceph")
      .args(ns_args)
      .arg(key)
      .stdin(Stdio::null())
      .stdout(Stdio::piped())
      .stderr(Stdio::inherit())
      .output()
      .map_err(Error::exec_subprocess(cmd_label))?;
    if out.status.success() {
      let mut value = String::from_utf8(out.stdout).map_err(Error::Utf8)?;
      if value.ends_with('\n') {
        value.pop();
      }
      let key_prefix = format!("{}: ", key);
      if value.starts_with(&key_prefix) {
        value.drain(..key_prefix.len());
      }
      Ok(value)
    } else {
      Err(Error::SubprocessStatus(cmd_label, out.status))
    }
  }

  fn set(self, key: &str, value: &str) -> Result<(), Error> {
    let (ns_args, cmd_label) = match self {
      Self::Global => (vec!["config", "set", "global"], "ceph config set global"),
      Self::Pool(pool) => (vec!["osd", "pool", "set", pool], "ceph osd pool set"),
    };
    let status = Command::new("ceph")
      .args(ns_args)
      .arg(key)
      .arg(value)
      .stdin(Stdio::null())
      .stdout(Stdio::inherit())
      .stderr(Stdio::inherit())
      .status()
      .map_err(Error::exec_subprocess(cmd_label))?;
    if status.success() {
      Ok(())
    } else {
      Err(Error::SubprocessStatus(cmd_label, status))
    }
  }
}
