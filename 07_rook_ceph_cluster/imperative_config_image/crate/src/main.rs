use crate::error::Error;
use std::process::ExitCode;

mod crush_map;
mod error;
mod settings;

fn main() -> ExitCode {
  env_logger::init();
  let (term_msg, exit_code) = match app() {
    Ok(()) => {
      log::info!("ok");
      ("ok", ExitCode::SUCCESS)
    }
    Err(err) => {
      let err_msg = err.to_string();
      log::error!("fatal: {}", err_msg);
      (err_msg.leak() as &str, ExitCode::FAILURE)
    }
  };
  let _ = std::fs::write("/dev/termination-log", term_msg);
  exit_code
}

fn app() -> Result<(), Error> {
  settings::configure().map_err(Error::with_context("failed to configure settings"))?;
  crush_map::configure().map_err(Error::with_context("failed to configure CRUSH map"))?;
  Ok(())
}
