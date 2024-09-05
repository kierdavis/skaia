use crate::error::Error;
use std::process::{Command, Stdio};

pub fn configure() -> Result<(), Error> {
  Namespace::Global.ensure_with_context("bluestore_compression_mode", "aggressive")?;
  Namespace::Global.ensure_with_context("mds_cache_memory_limit", "268435456")?;
  Namespace::Global.ensure_with_context("osd_deep_scrub_interval", "9676800.000000")?;
  Namespace::Global.ensure_with_context("osd_memory_target", "1073741824")?;
  Namespace::Global.ensure_with_context("osd_pool_default_size", "2")?;
  Namespace::Global.ensure_with_context("osd_scrub_max_interval", "2419200.000000")?;
  Namespace::Global.ensure_with_context("osd_scrub_min_interval", "1209600.000000")?;
  Ok(())
}

#[derive(Clone, Copy, Debug)]
enum Namespace {
  Global,
  // Pool(&'static str),
}

impl Namespace {
  fn ensure_with_context(self, key: &str, value: &str) -> Result<(), Error> {
    let context = format!("failed to ensure {}={} on {:?}", key, value, self).leak();
    self
      .ensure(key, value)
      .map_err(Error::with_context(context))
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
    let cmd = match self {
      Self::Global => vec!["ceph", "config", "show", "mgr.a", key],
    };
    let out = Command::new(cmd[0])
      .args(&cmd[1..])
      .stdin(Stdio::null())
      .stdout(Stdio::piped())
      .stderr(Stdio::inherit())
      .output()
      .map_err(Error::exec_subprocess(&cmd))?;
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
      Err(Error::subprocess_status(&cmd, out.status))
    }
  }

  fn set(self, key: &str, value: &str) -> Result<(), Error> {
    let cmd = match self {
      Self::Global => vec!["ceph", "config", "set", "global", key, value],
    };
    let status = Command::new(cmd[0])
      .args(&cmd[1..])
      .stdin(Stdio::null())
      .stdout(Stdio::inherit())
      .stderr(Stdio::inherit())
      .status()
      .map_err(Error::exec_subprocess(&cmd))?;
    if status.success() {
      Ok(())
    } else {
      Err(Error::subprocess_status(&cmd, status))
    }
  }
}
