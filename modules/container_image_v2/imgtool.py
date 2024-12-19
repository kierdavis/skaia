import argparse
import contextlib
import hashlib
import json
import os
import pathlib
import subprocess
import sys


class InvalidImageError(Exception):
  pass

class PlatformMismatch(Exception):
  pass


def log(msg):
  print(f"[imgtool] {msg}", file=sys.stderr)


def iter_manifest_refs(oci_path, index_path=None):
  if index_path is None:
    index_path = oci_path / "index.json"
  with open(index_path, "r") as f:
    index = json.load(f)
  if index["mediaType"] != "application/vnd.oci.image.index.v1+json":
    raise InvalidImageError(f"index {index_path} has unrecognised mediaType: {index['mediaType']}")
  for manifest_ref in index["manifests"]:
    if manifest_ref["mediaType"] == "application/vnd.oci.image.index.v1+json":
      nested_index_path = oci_path / "blobs" / manifest_ref["digest"].replace(":", "/")
      yield from iter_manifest_refs(oci_path, nested_index_path)
    elif manifest_ref["mediaType"] in ("application/vnd.oci.image.manifest.v1+json", "application/vnd.docker.distribution.manifest.v2+json"):
      yield manifest_ref
    else:
      raise InvalidImageError(f"manifest {manifest_ref['digest']} referenced by index {index_path} has unrecognised mediaType: {manifest_ref['mediaType']}")


def decompress_and_digest(in_path, out_path, decompressor):
  log(f"decompressing {in_path}...")
  decompress_proc = subprocess.Popen(
    [decompressor, "-c", str(in_path)],
    stdin=subprocess.DEVNULL,
    stdout=subprocess.PIPE,
  )
  tee_proc = subprocess.Popen(
    ["tee", str(out_path)],
    stdin=decompress_proc.stdout,
    stdout=subprocess.PIPE,
  )
  sha256sum_proc = subprocess.Popen(
    ["sha256sum"],
    stdin=tee_proc.stdout,
    stdout=subprocess.PIPE,
  )
  for proc in [decompress_proc, tee_proc, sha256sum_proc]:
    proc.wait()
  return "sha256:" + sha256sum_proc.stdout.read().decode("ascii").split()[0]


def cmd_post_fetch(args):
  img_path = pathlib.Path(args.img_path)
  (img_path / "diffs/sha256").mkdir(parents=True, exist_ok=True)

  for manifest_ref in iter_manifest_refs(img_path / "oci"):
    manifest_path = img_path / "oci/blobs" / manifest_ref["digest"].replace(":", "/")
    with open(manifest_path, "r") as f:
      manifest = json.load(f)
    if manifest["mediaType"] not in ("application/vnd.oci.image.manifest.v1+json", "application/vnd.docker.distribution.manifest.v2+json"):
      raise InvalidImageError(f"manifest {manifest_path} has unrecognised mediaType: {manifest['mediaType']}")

    for layer_ref in manifest["layers"]:
      blob_path = img_path / "oci/blobs" / layer_ref["digest"].replace(":", "/")
      if layer_ref["mediaType"] in ("application/vnd.oci.image.layer.v1.tar+gzip", "application/vnd.docker.image.rootfs.diff.tar.gzip"):
        diff_staging_path = img_path / "diffs/staging"
        diff_digest = decompress_and_digest(blob_path, diff_staging_path, decompressor="unpigz")
        diff_path = img_path / "diffs" / diff_digest.replace(":", "/")
        diff_staging_path.rename(diff_path)
      elif layer_ref["mediaType"] in ("application/vnd.in-toto+json",):
        pass # This "layer" is some kind of metadata, not a diff. Do nothing.
      else:
        raise InvalidImageError(f"layer {layer_ref['digest']} referenced by manifest {manifest_path} has unrecognised mediaType: {layer_ref['mediaType']}")


def matches_desired_platform(manifest_ref, desired_arch="amd64", desired_os="linux"):
  arch = manifest_ref.get("platform", {}).get("architecture")
  arch_ok = arch is None or arch == desired_arch
  os = manifest_ref.get("platform", {}).get("os")
  os_ok = os is None or os == desired_os
  return arch_ok and os_ok


@contextlib.contextmanager
def overlay_mounted(mountpoint, lowerdirs, upperdir=None, workdir=None, options=None):
  mountpoint.mkdir(parents=True, exist_ok=True)
  all_options = [f"lowerdir={':'.join(map(str, lowerdirs))}"]
  if upperdir is not None:
    all_options.append(f"upperdir={upperdir}")
  if workdir is not None:
    workdir.mkdir(parents=True, exist_ok=True)
    all_options.append(f"workdir={workdir}")
  if options:
    all_options.extend(options)
  mount_cmd = ["mount", "-toverlay", "-o" + ",".join(all_options), "overlay", str(mountpoint)]
  log(" ".join(mount_cmd))
  try:
    subprocess.run(mount_cmd, stdin=subprocess.DEVNULL, stdout=sys.stderr, check=True)
  except subprocess.CalledProcessError:
    subprocess.run(["dmesg"], stdout=sys.stderr)
    raise
  try:
    yield
  finally:
    subprocess.run(["umount", str(mountpoint)], stdin=subprocess.DEVNULL, stdout=sys.stderr)


@contextlib.contextmanager
def ephemeral_dir(path):
  path = pathlib.Path(path)
  if path.exists():
    yield
  else:
    path.mkdir(parents=True, exist_ok=True)
    try:
      yield
    finally:
      try:
        path.rmdir()
      except:
        pass


@contextlib.contextmanager
def ephemeral_file(path, content, mode=0o644):
  path = pathlib.Path(path)
  path.write_text(content)
  path.chmod(mode)
  try:
    yield
  finally:
    path.unlink(missing_ok=True)


def run(from_path, config, script):
  # We're root, inside a VM, inside a Nix build.
  # The host's Nix store is mounted at the usual location.
  # It's assumed that the current working directory is backed by disk, not RAM.

  with contextlib.ExitStack() as ctx:
    # lowerdirs[0] is the topmost layer, lowerdirs[-1] is the bottommost layer - same as required by overlayfs mount option.
    curr_tier_lowerdirs = []
    for layer_idx, diff_digest in enumerate(config["rootfs"]["diff_ids"]):
      diff_tarball_path = from_path / "diffs" / diff_digest.replace(":", "/")
      diff_extract_dir = pathlib.Path("layer") / str(layer_idx)
      diff_extract_dir.mkdir(parents=True, exist_ok=True)
      log(f"extracting {diff_tarball_path} to {diff_extract_dir}...")
      subprocess.run(
        ["tar", "--extract", f"--file={diff_tarball_path}", f"--directory={diff_extract_dir}"],
        stdin=subprocess.DEVNULL,
        stdout=sys.stderr,
        check=True,
      )
      curr_tier_lowerdirs.insert(0, diff_extract_dir)

    max_lowerdirs_per_overlay = 28  # by experimentation
    next_tier_lowerdirs = []
    overlay_idx = 0

    while len(curr_tier_lowerdirs) + len(next_tier_lowerdirs) > max_lowerdirs_per_overlay:
      group_mountpoint = pathlib.Path("group") / str(overlay_idx)
      group_size = min(max_lowerdirs_per_overlay + 1, len(curr_tier_lowerdirs))
      ctx.enter_context(overlay_mounted(
        mountpoint = group_mountpoint,
        lowerdirs = curr_tier_lowerdirs[-group_size+1:],
        upperdir = curr_tier_lowerdirs[-group_size],
        workdir = pathlib.Path("work") / str(overlay_idx),
        options = ["ro"],
      ))
      curr_tier_lowerdirs = curr_tier_lowerdirs[:-group_size]
      next_tier_lowerdirs.insert(0, group_mountpoint)
      if not curr_tier_lowerdirs:
        curr_tier_lowerdirs = next_tier_lowerdirs
        next_tier_lowerdirs = []
      overlay_idx += 1

    ctx.enter_context(overlay_mounted(
      mountpoint = pathlib.Path("mnt"),
      lowerdirs = curr_tier_lowerdirs + next_tier_lowerdirs,
      workdir = pathlib.Path("work") / str(overlay_idx),
      upperdir = pathlib.Path("newlayer"),
      options = ["volatile"],
    ))

    for subdir in ["dev", "proc", "sys"]:
      ctx.enter_context(ephemeral_dir(f"mnt/{subdir}"))

    script_filename = "Of9lmrc1an0"  # difficult-to-predict name, to avoid conflicting with any image content
    ctx.enter_context(ephemeral_file(f"mnt/{script_filename}", script, mode=0o755))

    log(f"running script...")
    env = " ".join(config.get("config", {}).get("Env", []))
    subprocess.run(
      [
        "unshare",
        "-imnpuf",
        "--mount-proc",
        "sh",
        "-e",
        "-c",
        f"chroot=$(type -p chroot); mount --rbind /dev mnt/dev; mount --rbind /proc mnt/proc; mount --rbind /sys mnt/sys; exec env --ignore-environment {env} $chroot mnt /{script_filename}",
      ],
      check=True,
    )


def cmd_append(args):
  from_path = pathlib.Path(getattr(args, "from"))
  out_path = pathlib.Path(args.out)

  manifest_refs = [ref for ref in iter_manifest_refs(from_path / "oci") if matches_desired_platform(ref)]
  if not manifest_refs:
    raise PlatformMismatch("no manifest is suitable for desired platform")
  if len(manifest_refs) > 1:
    raise PlatformMismatch("multiple manifests are suitable for desired platform")
  [manifest_ref] = manifest_refs

  manifest_path = from_path / "oci/blobs" / manifest_ref["digest"].replace(":", "/")
  with open(manifest_path, "r") as f:
    manifest = json.load(f)
  if manifest["mediaType"] not in ("application/vnd.oci.image.manifest.v1+json", "application/vnd.docker.distribution.manifest.v2+json"):
    raise InvalidImageError(f"manifest {manifest_path} has unrecognised mediaType: {manifest['mediaType']}")

  config_path = from_path / "oci/blobs" / manifest["config"]["digest"].replace(":", "/")
  with open(config_path, "r") as f:
    config = json.load(f)
  if config["rootfs"]["type"] != "layers":
    raise InvalidImageError(f"expected rootfs.type to be 'layers' in {config_path}")

  (out_path / "diffs/sha256").mkdir(parents=True, exist_ok=True)
  for diff_digest in config["rootfs"]["diff_ids"]:
    diff_rel_path = diff_digest.replace(":", "/")
    (out_path / "diffs" / diff_rel_path).symlink_to(from_path / "diffs" / diff_rel_path)
  (out_path / "oci/blobs/sha256").mkdir(parents=True, exist_ok=True)
  for blob_ref in manifest["layers"]:
    blob_rel_path = blob_ref["digest"].replace(":", "/")
    (out_path / "oci/blobs" / blob_rel_path).symlink_to(from_path / "oci/blobs" / blob_rel_path)

  if args.content is not None or args.script is not None:
    pathlib.Path("newlayer").mkdir(parents=True, exist_ok=True)

    if args.content is not None:
      log(f"copying contents of {args.content} to new layer")
      subprocess.run(
        ["rsync", "--archive", f"{args.content}/", "newlayer/"],
        stdin=subprocess.DEVNULL,
        stdout=sys.stderr,
        check=True,
      )

    if args.script is not None:
      run(from_path=from_path, config=config, script=args.script)

    log("packing new layer blob...")
    new_diff_staging_path = out_path / "diffs/staging"
    new_blob_staging_path = out_path / "oci/blobs/staging"
    tar_proc = subprocess.Popen(
      [
        "tar",
        "--create",
        "--directory=newlayer",
        "--hard-dereference",
        "--sort=name",
        f"--mtime=@{os.environ.get('SOURCE_DATE_EPOCH', 1)}",
        ".",
      ],
      stdin=subprocess.DEVNULL,
      stdout=subprocess.PIPE,
    )
    diff_sha256sum_proc = subprocess.Popen(
      ["sha256sum"],
      stdin=subprocess.PIPE,
      stdout=subprocess.PIPE,
    )
    diff_tee_proc = subprocess.Popen(
      ["tee", str(new_diff_staging_path), f"/dev/fd/{diff_sha256sum_proc.stdin.fileno()}"],
      pass_fds=(diff_sha256sum_proc.stdin.fileno(),),
      stdin=tar_proc.stdout,
      stdout=subprocess.PIPE,
    )
    diff_sha256sum_proc.stdin.close()
    pigz_proc = subprocess.Popen(
      ["pigz"],
      stdin=diff_tee_proc.stdout,
      stdout=subprocess.PIPE,
    )
    blob_tee_proc = subprocess.Popen(
      ["tee", str(new_blob_staging_path)],
      stdin=pigz_proc.stdout,
      stdout=subprocess.PIPE,
    )
    blob_sha256sum_proc = subprocess.Popen(
      ["sha256sum"],
      stdin=blob_tee_proc.stdout,
      stdout=subprocess.PIPE,
    )
    for proc in [tar_proc, diff_sha256sum_proc, diff_tee_proc, pigz_proc, blob_tee_proc, blob_sha256sum_proc]:
      proc.wait()

    new_diff_digest = "sha256:" + diff_sha256sum_proc.stdout.read().decode("ascii").split()[0]
    new_diff_path = out_path / "diffs" / new_diff_digest.replace(":", "/")
    if new_diff_path.exists():
      new_diff_staging_path.unlink()
    else:
      new_diff_staging_path.rename(new_diff_path)

    new_blob_digest = "sha256:" + blob_sha256sum_proc.stdout.read().decode("ascii").split()[0]
    new_blob_path = out_path / "oci/blobs" / new_blob_digest.replace(":", "/")
    if new_blob_path.exists():
      new_blob_staging_path.unlink()
    else:
      new_blob_staging_path.rename(new_blob_path)

    config["rootfs"]["diff_ids"].append(new_diff_digest)
    config["history"].append({"comment": "imgtool"})
    manifest["layers"].append({
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "digest": new_blob_digest,
      "size": new_blob_path.stat().st_size,
    })

  for pair in args.env:
    name, _ = pair.split("=", 1)
    env_list = config.setdefault("config", {}).get("Env", [])
    env_list = [x for x in env_list if not x.startswith(name + "=")]
    env_list.append(pair)
    config["config"]["Env"] = env_list

  new_config_blob = json.dumps(config, separators=(",", ":")).encode("utf-8")
  new_config_digest = "sha256:" + hashlib.sha256(new_config_blob).hexdigest()
  (out_path / "oci/blobs" / new_config_digest.replace(":", "/")).write_bytes(new_config_blob)

  manifest["config"]["digest"] = new_config_digest
  manifest["config"]["size"] = len(new_config_blob)
  new_manifest_blob = json.dumps(manifest, separators=(",", ":")).encode("utf-8")
  new_manifest_digest = "sha256:" + hashlib.sha256(new_manifest_blob).hexdigest()
  (out_path / "oci/blobs" / new_manifest_digest.replace(":", "/")).write_bytes(new_manifest_blob)

  with open(out_path / "oci/index.json", "w") as f:
    json.dump({
      "schemaVersion": 2,
      "mediaType": "application/vnd.oci.image.index.v1+json",
      "manifests": [{
        "mediaType": manifest["mediaType"],
        "digest": new_manifest_digest,
        "size": len(new_manifest_blob),
      }],
    }, f, separators=(",", ":"))

  (out_path / "oci/oci-layout").write_text("""{"imageLayoutVersion": "1.0.0"}""")


def main():
  parser = argparse.ArgumentParser()
  subparsers = parser.add_subparsers()

  post_fetch_parser = subparsers.add_parser("post-fetch")
  post_fetch_parser.set_defaults(cmd=cmd_post_fetch)
  post_fetch_parser.add_argument("img_path")

  append_parser = subparsers.add_parser("append")
  append_parser.set_defaults(cmd=cmd_append)
  append_parser.add_argument("from", metavar="IMAGE_PATH")
  append_parser.add_argument("out", metavar="IMAGE_PATH")
  append_parser.add_argument("--content", metavar="DIR", default=None)
  append_parser.add_argument("--script", metavar="SCRIPT", default=None)
  append_parser.add_argument("--env", metavar="NAME=VALUE", default=[], action="append")

  args = parser.parse_args()
  args.cmd(args)


if __name__ == "__main__":
  main()
