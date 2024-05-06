use thiserror::Error;

#[derive(Debug, Error)]
pub enum Error {
  #[error("failed to execute subprocess {0:?}: {1}")]
  ExecSubprocess(&'static str, std::io::Error),
  #[error("subprocess {0:?} exited with status {1}")]
  SubprocessStatus(&'static str, std::process::ExitStatus),
  #[error("failed to decode UTF-8: {0}")]
  Utf8(std::string::FromUtf8Error),
  #[error("{0}: {1}")]
  WithContext(&'static str, Box<Self>),
  // #[error("failed to write to stdin of subprocess {0:?}: {1}")]
  // WriteSubprocessStdin(&'static str, std::io::Error),
}

impl Error {
  pub fn exec_subprocess(cmdline: &'static str) -> impl FnOnce(std::io::Error) -> Self {
    move |cause| Self::ExecSubprocess(cmdline, cause)
  }
  pub fn with_context(context: &'static str) -> impl FnOnce(Self) -> Self {
    move |cause| Self::WithContext(context, Box::new(cause))
  }
  // pub fn write_subprocess_stdin(cmdline: &'static str) -> impl FnOnce(std::io::Error) -> Self {
  //   move |cause| Self::WriteSubprocessStdin(cmdline, cause)
  // }
}
