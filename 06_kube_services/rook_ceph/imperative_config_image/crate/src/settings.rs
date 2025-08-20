use crate::error::Error;
use std::process::{Command, Stdio};

pub fn configure() -> Result<(), Error> {
  Namespace::Dashboard.ensure_env_with_context("grafana-api-password", "GRAFANA_PASSWORD")?;
  Namespace::Dashboard.ensure_env_with_context("grafana-api-url", "GRAFANA_URL")?;
  Namespace::Dashboard.ensure_env_with_context("grafana-api-username", "GRAFANA_USERNAME")?;
  Namespace::Global.ensure_with_context("bluestore_compression_mode", "passive")?;
  Namespace::Global.ensure_with_context("mds_cache_memory_limit", "268435456")?;
  Namespace::Global.ensure_with_context("osd_deep_scrub_interval", "9676800.000000")?;
  Namespace::Global.ensure_with_context("osd_memory_target", "1073741824")?;
  Namespace::Global.ensure_with_context("osd_pool_default_pg_autoscale_mode", "warn")?;
  Namespace::Global.ensure_with_context("osd_pool_default_size", "2")?;
  Namespace::Global.ensure_with_context("osd_scrub_max_interval", "2419200.000000")?;
  Namespace::Global.ensure_with_context("osd_scrub_min_interval", "1209600.000000")?;
  Namespace::Pool(".mgr").ensure_with_context("size", "2")?;
  Ok(())
}

#[derive(Clone, Copy, Debug)]
enum Namespace {
  Dashboard,
  Global,
  Pool(&'static str),
}

impl Namespace {
  fn ensure_env_with_context(self, key: &str, var_name: &str) -> Result<(), Error> {
    let context = format!("failed to ensure {}=${} on {:?}", key, var_name, self).leak();
    self
      .ensure_env(key, var_name)
      .map_err(Error::with_context(context))
  }

  fn ensure_with_context(self, key: &str, value: &str) -> Result<(), Error> {
    let context = format!("failed to ensure {}={} on {:?}", key, value, self).leak();
    self
      .ensure(key, value)
      .map_err(Error::with_context(context))
  }

  fn ensure_env(self, key: &str, var_name: &str) -> Result<(), Error> {
    use std::env::VarError::*;
    match std::env::var(var_name) {
      Ok(val) => self.ensure(key, &val),
      Err(NotPresent) => {
        log::warn!(
          "{:?} {} not controlled because environment variable {} is not set",
          self,
          key,
          var_name
        );
        Ok(())
      }
      Err(NotUnicode(_)) => {
        log::warn!(
          "{:?} {} not controlled because environment variable {} is invalid Unicode",
          self,
          key,
          var_name
        );
        Ok(())
      }
    }
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
      Self::Dashboard => vec!["ceph", "dashboard", format!("get-{}", key).leak()],
      Self::Global => vec!["ceph", "config", "show", "mgr.a", key],
      Self::Pool(pool) => vec!["ceph", "osd", "pool", "get", pool, key],
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
      Self::Dashboard => match key {
        "grafana-api-password" => {
          use std::io::Write;
          const PATH: &'static str = "/tmp/grafana-api-password";
          std::fs::File::create(PATH)
            .map_err(Error::open_file(PATH))?
            .write_all(value.as_bytes())
            .map_err(Error::write_file(PATH))?;
          vec![
            "ceph",
            "dashboard",
            format!("set-{}", key).leak(),
            "-i",
            PATH,
          ]
        }
        _ => vec!["ceph", "dashboard", format!("set-{}", key).leak(), value],
      },
      Self::Global => vec!["ceph", "config", "set", "global", key, value],
      Self::Pool(pool) => vec!["ceph", "osd", "pool", "set", pool, key, value],
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
