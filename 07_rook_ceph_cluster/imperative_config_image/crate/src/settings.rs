use crate::error::Error;
use std::process::{Command, Stdio};

pub fn configure() -> Result<(), Error> {
  ensure_with_context("bluestore_compression_mode", "aggressive")?;
  ensure_with_context("osd_pool_default_size", "2")?;
  ensure_with_context("osd_scrub_max_interval", "3024000.000000")?;
  ensure_with_context("osd_scrub_min_interval", "1814400.000000")?;
  Ok(())
}

fn ensure_with_context(key: &str, value: &str) -> Result<(), Error> {
  let context = format!("failed to ensure {}={}", key, value).leak();
  ensure(key, value).map_err(Error::with_context(context))
}

fn ensure(key: &str, desired_value: &str) -> Result<(), Error> {
  let current_value = get(key)?;
  if current_value == desired_value {
    log::info!("{} already equals {}", key, desired_value);
    Ok(())
  } else {
    log::info!(
      "changing {} from {} to {}",
      key,
      current_value,
      desired_value
    );
    set(key, desired_value)
  }
}

fn get(key: &str) -> Result<String, Error> {
  const CMD: &'static str = "ceph config show";
  let out = Command::new("ceph")
    .args(&["config", "show", "mgr.a", key])
    .stdin(Stdio::null())
    .stdout(Stdio::piped())
    .stderr(Stdio::inherit())
    .output()
    .map_err(Error::exec_subprocess(CMD))?;
  if out.status.success() {
    let mut value = String::from_utf8(out.stdout).map_err(Error::Utf8)?;
    if value.ends_with('\n') { value.pop(); }
    Ok(value)
  } else {
    Err(Error::SubprocessStatus(CMD, out.status))
  }
}

fn set(key: &str, value: &str) -> Result<(), Error> {
  const CMD: &'static str = "ceph config set";
  let status = Command::new("ceph")
    .args(&["config", "set", "global", key, value])
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
