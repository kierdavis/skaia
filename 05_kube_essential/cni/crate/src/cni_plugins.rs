use crate::error::Error;
use crate::util::Never;
use futures_util::future::{TryFutureExt, pending};
use std::path::Path;
use tokio::fs::read_dir;

pub fn install_then_sleep(
  src_dir: &'static Path,
  dest_dir: &'static Path,
) -> impl Future<Output = Result<Never, Error>> {
  install(src_dir, dest_dir).and_then(|()| pending())
}

async fn install(src_dir: &'static Path, dest_dir: &'static Path) -> Result<(), Error> {
  let mut entries = read_dir(src_dir).await.map_err(Error::read_dir(src_dir))?;
  while let Some(entry) = entries
    .next_entry()
    .await
    .map_err(Error::read_dir(src_dir))?
  {
    let src_file = entry.path();
    let mut dest_file = dest_dir.to_path_buf();
    dest_file.push(entry.file_name());
    log::info!("copying {} to {}", src_file.display(), dest_file.display());
    tokio::fs::copy(&src_file, &dest_file)
      .await
      .map_err(Error::copy_file(&src_file, &dest_file))?;
  }
  Ok(())
}
