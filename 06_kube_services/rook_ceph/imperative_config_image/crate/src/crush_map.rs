use crate::error::Error;
use lazy_static::lazy_static;
use regex::Regex;
use similar::TextDiff;
use std::borrow::Cow;
use std::io::Write;
use std::process::{Command, Stdio};

pub fn configure() -> Result<(), Error> {
  let before = read().map_err(Error::with_context("read CRUSH map"))?;
  let after = mutate(&before);
  let diff = TextDiff::from_lines(before.as_str(), after.as_ref());
  let is_equal = diff
    .ops()
    .iter()
    .all(|op| matches!(op, similar::DiffOp::Equal { .. }));
  if is_equal {
    log::info!("CRUSH map up to date");
    Ok(())
  } else {
    log::info!("changing CRUSH map:\n{}", diff.unified_diff());
    write(&after).map_err(Error::with_context("write new CRUSH map"))
  }
}

fn mutate(map: &str) -> Cow<str> {
  map.into()
}

fn read() -> Result<String, Error> {
  getcrushmap().and_then(|compiled| decompile(&compiled))
}

fn getcrushmap() -> Result<Vec<u8>, Error> {
  const CMD: &'static str = "ceph osd getcrushmap";
  let out = Command::new("ceph")
    .args(&["osd", "getcrushmap"])
    .stdin(Stdio::null())
    .stdout(Stdio::piped())
    .stderr(Stdio::inherit())
    .output()
    .map_err(Error::exec_subprocess(CMD))?;
  if out.status.success() {
    Ok(out.stdout)
  } else {
    Err(Error::SubprocessStatus(CMD, out.status))
  }
}

fn decompile(input: &[u8]) -> Result<String, Error> {
  const CMD: &'static str = "crushtool -d";
  let mut proc = Command::new("crushtool")
    .args(&["-d", "-"])
    .stdin(Stdio::piped())
    .stdout(Stdio::piped())
    .stderr(Stdio::inherit())
    .spawn()
    .map_err(Error::exec_subprocess(CMD))?;
  proc
    .stdin
    .as_mut()
    .unwrap()
    .write_all(input)
    .map_err(Error::write_subprocess_stdin(CMD))?;
  let out = proc
    .wait_with_output()
    .map_err(Error::exec_subprocess(CMD))?;
  if out.status.success() {
    String::from_utf8(out.stdout).map_err(Error::Utf8)
  } else {
    Err(Error::SubprocessStatus(CMD, out.status))
  }
}

fn write(input: &str) -> Result<(), Error> {
  compile(input).and_then(|compiled| setcrushmap(&compiled))
}

fn compile(input: &str) -> Result<Vec<u8>, Error> {
  const CMD: &'static str = "crushtool -c";
  let mut proc = Command::new("crushtool")
    .args(&["-c", "/dev/stdin", "-o", "/dev/stdout"])
    .stdin(Stdio::piped())
    .stdout(Stdio::piped())
    .stderr(Stdio::inherit())
    .spawn()
    .map_err(Error::exec_subprocess(CMD))?;
  proc
    .stdin
    .as_mut()
    .unwrap()
    .write_all(input.as_ref())
    .map_err(Error::write_subprocess_stdin(CMD))?;
  let out = proc
    .wait_with_output()
    .map_err(Error::exec_subprocess(CMD))?;
  if out.status.success() {
    Ok(out.stdout)
  } else {
    Err(Error::SubprocessStatus(CMD, out.status))
  }
}

fn setcrushmap(input: &[u8]) -> Result<(), Error> {
  const CMD: &'static str = "ceph osd setcrushmap";
  let mut proc = Command::new("ceph")
    .args(&["osd", "setcrushmap", "-i", "-"])
    .stdin(Stdio::piped())
    .stdout(Stdio::inherit())
    .stderr(Stdio::inherit())
    .spawn()
    .map_err(Error::exec_subprocess(CMD))?;
  proc
    .stdin
    .as_mut()
    .unwrap()
    .write_all(input)
    .map_err(Error::write_subprocess_stdin(CMD))?;
  let status = proc.wait().map_err(Error::exec_subprocess(CMD))?;
  if status.success() {
    Ok(())
  } else {
    Err(Error::SubprocessStatus(CMD, status))
  }
}
