use std::fmt;

#[derive(Debug)]
pub struct Error(String);

impl fmt::Display for Error {
  fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
    f.write_str(&self.0)
  }
}

impl From<kube::config::InClusterError> for Error {
  fn from(err: kube::config::InClusterError) -> Self {
    Self(format!(
      "failed to get in-cluster Kubernetes config: {}",
      err
    ))
  }
}

impl Error {
  pub fn channel_closed(name: &'static str) -> Self {
    Self(format!("{} channel was unexpectedly closed", name))
  }

  pub fn get_env(name: &'static str) -> impl FnOnce(std::env::VarError) -> Self {
    move |err| {
      Self(format!(
        "failed to get environment variable {}: {}",
        name, err
      ))
    }
  }

  pub fn kube_client(err: kube::Error) -> Self {
    Self(format!("failed to initialise Kubernetes client: {}", err))
  }

  pub fn kube_event_stream_terminated() -> Self {
    Self(String::from("event stream terminated unexpectedly"))
  }

  pub fn parse_service_cidr(
    input: &'static str,
  ) -> impl FnOnce(cidr::errors::NetworkParseError) -> Self {
    move |err| {
      Self(format!(
        "failed to parse SERVICE_CIDRS element {:?}: {}",
        input, err
      ))
    }
  }

  pub fn serialize_json(err: serde_json::Error) -> Self {
    Self(format!("failed to serialize JSON: {}", err))
  }

  pub fn subprocess_exec(cmd: &str) -> impl FnOnce(std::io::Error) -> Self {
    move |err| Self(format!("failed to execute subprocess {}: {}", cmd, err))
  }

  pub fn subprocess_status(cmd: &str, status: std::process::ExitStatus) -> Self {
    Self(format!("subprocess {} exited with status {}", cmd, status))
  }

  pub fn task_terminated(name: &'static str) -> impl FnOnce(tokio::task::JoinError) -> Self {
    move |err| Self(format!("task {} terminated unexpectedly: {}", name, err))
  }

  pub fn write_file(path: &'static str) -> impl FnOnce(std::io::Error) -> Self {
    move |err| Self(format!("failed to write to {}: {}", path, err))
  }
}
