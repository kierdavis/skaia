import argparse
import contextlib
import hashlib
import json
import os
import pathlib
import shlex
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
  if index["mediaType"] not in ("application/vnd.oci.image.index.v1+json", "application/vnd.docker.distribution.manifest.list.v2+json"):
    raise InvalidImageError(f"index {index_path} has unrecognised mediaType: {index['mediaType']}")
  for manifest_ref in index["manifests"]:
    if manifest_ref["mediaType"] in ("application/vnd.oci.image.index.v1+json", "application/vnd.docker.distribution.manifest.list.v2+json"):
      nested_index_path = oci_path / "blobs" / manifest_ref["digest"].replace(":", "/")
      yield from iter_manifest_refs(oci_path, nested_index_path)
    elif manifest_ref["mediaType"] in ("application/vnd.oci.image.manifest.v1+json", "application/vnd.docker.distribution.manifest.v2+json"):
      yield manifest_ref
    else:
      raise InvalidImageError(f"manifest {manifest_ref['digest']} referenced by index {index_path} has unrecognised mediaType: {manifest_ref['mediaType']}")


def matches_desired_platform(manifest_ref, desired_arch="amd64", desired_os="linux"):
  arch = manifest_ref.get("platform", {}).get("architecture")
  arch_ok = arch is None or arch == desired_arch
  os = manifest_ref.get("platform", {}).get("os")
  os_ok = os is None or os == desired_os
  return arch_ok and os_ok


def select_and_load_manifest(img_path):
  manifest_refs = [ref for ref in iter_manifest_refs(img_path / "oci") if matches_desired_platform(ref)]
  if not manifest_refs:
    raise PlatformMismatch("no manifest is suitable for desired platform")
  if len(manifest_refs) > 1:
    raise PlatformMismatch("multiple manifests are suitable for desired platform")
  [manifest_ref] = manifest_refs

  manifest_path = img_path / "oci/blobs" / manifest_ref["digest"].replace(":", "/")
  with open(manifest_path, "r") as f:
    manifest = json.load(f)
  if manifest["mediaType"] not in ("application/vnd.oci.image.manifest.v1+json", "application/vnd.docker.distribution.manifest.v2+json"):
    raise InvalidImageError(f"manifest {manifest_path} has unrecognised mediaType: {manifest['mediaType']}")

  config_path = img_path / "oci/blobs" / manifest["config"]["digest"].replace(":", "/")
  with open(config_path, "r") as f:
    config = json.load(f)
  if config["rootfs"]["type"] != "layers":
    raise InvalidImageError(f"expected rootfs.type to be 'layers' in {config_path}")

  return manifest, config


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
    if proc.wait() != 0:
      raise subprocess.CalledProcessError(returncode=proc.returncode, cmd=repr(proc.args))
  return "sha256:" + sha256sum_proc.stdout.read().decode("ascii").split()[0]


def subcmd_post_fetch(args):
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


def mount_image(ctx, img_path, workspace_path, img_config=None, upperdir=None):
  if img_config is None:
    _, img_config = select_and_load_manifest(img_path)

  # lowerdirs[0] is the topmost layer, lowerdirs[-1] is the bottommost layer - same order as required by overlayfs mount option.
  curr_tier_lowerdirs = []
  for layer_idx, diff_digest in enumerate(img_config["rootfs"]["diff_ids"]):
    diff_tarball_path = img_path / "diffs" / diff_digest.replace(":", "/")
    diff_extract_dir = workspace_path / "layer" / str(layer_idx)
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
    group_mountpoint = workspace_path / "group" / str(overlay_idx)
    group_size = min(max_lowerdirs_per_overlay + 1, len(curr_tier_lowerdirs))
    ctx.enter_context(overlay_mounted(
      mountpoint = group_mountpoint,
      lowerdirs = curr_tier_lowerdirs[-group_size+1:],
      upperdir = curr_tier_lowerdirs[-group_size],
      workdir = workspace_path / "work" / str(overlay_idx),
      options = ["ro"],
    ))
    curr_tier_lowerdirs = curr_tier_lowerdirs[:-group_size]
    next_tier_lowerdirs.insert(0, group_mountpoint)
    if not curr_tier_lowerdirs:
      curr_tier_lowerdirs = next_tier_lowerdirs
      next_tier_lowerdirs = []
    overlay_idx += 1

  mountpoint = workspace_path / "mnt"
  ctx.enter_context(overlay_mounted(
    mountpoint = mountpoint,
    lowerdirs = curr_tier_lowerdirs + next_tier_lowerdirs,
    workdir = workspace_path / "work" / str(overlay_idx) if upperdir is not None else None,
    upperdir = upperdir,
    options = ["volatile"] if upperdir is not None else ["ro"],
  ))
  return mountpoint


def run(in_path, config, script):
  # We're root, inside a VM, inside a Nix build.
  # The host's Nix store is mounted at the usual location.
  # It's assumed that the current working directory is backed by disk, not RAM.

  with contextlib.ExitStack() as ctx:
    mountpoint = mount_image(ctx, in_path, workspace_path=pathlib.Path("run"), img_config=config, upperdir=pathlib.Path("newlayer"))

    for subdir in ["dev", "proc", "sys"]:
      ctx.enter_context(ephemeral_dir(mountpoint / subdir))

    env = list(config.get("config", {}).get("Env", []))
    for var_name in ["SOURCE_DATE_EPOCH"]:
      if var_name in os.environ:
        env.insert(0, f"{var_name}={os.environ[var_name]}")

    log(f"running script...")
    subprocess.run(
      [
        "unshare",
        "-imnpuf",
        "--mount-proc",
        "sh",
        "-euc",
        f"for x in dev proc sys; do mount --rbind /$x {mountpoint}/$x; done; exec env --ignore-environment {' '.join(env)} $(type -p chroot) {mountpoint} sh -euc {shlex.quote(script)}",
      ],
      check=True,
    )


def subcmd_create_layer(args):
  in_path = pathlib.Path(getattr(args, "in"))
  out_path = pathlib.Path(args.out)
  with open(args.customisations) as f:
    customisations = json.load(f)

  manifest, config = select_and_load_manifest(in_path)

  pathlib.Path("newlayer").mkdir(parents=True, exist_ok=True)

  for i, entry in enumerate(customisations.get("add", [])):
    with contextlib.ExitStack() as ctx:
      if entry.get("from"):
        src_root = mount_image(ctx, pathlib.Path(entry["from"]), workspace_path=pathlib.Path(f"add{i}"))
      else:
        src_root = pathlib.Path("/")
      assert entry["src"].startswith("/")
      src = src_root / entry["src"].lstrip("/")
      assert entry["dest"].startswith("/")
      dest = pathlib.Path("newlayer") / entry["dest"].lstrip("/")
      log(f"copying {src} to {dest}...")
      dest.parent.mkdir(parents=True, exist_ok=True)
      rsync_cmd = ["rsync", "--archive"]
      if entry.get("dereference", True):
        rsync_cmd.append("--copy-links")
      if src.is_dir():
        rsync_cmd += [f"{src}/", f"{dest}/"]
      else:
        rsync_cmd += [str(src), str(dest)]
      subprocess.run(
        rsync_cmd,
        stdin=subprocess.DEVNULL,
        stdout=sys.stderr,
        check=True,
      )

  if customisations.get("run"):
    run(in_path=in_path, config=config, script=customisations["run"])

  log("packing blob...")
  out_path.mkdir(parents=True, exist_ok=True)
  new_diff_path = out_path / "diff"
  new_blob_path = out_path / "blob"
  tar_proc = subprocess.Popen(
    [
      "tar",
      "--create",
      "--directory=newlayer",
      "--exclude=./imgbuild",
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
    ["tee", str(new_diff_path), f"/dev/fd/{diff_sha256sum_proc.stdin.fileno()}"],
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
    ["tee", str(new_blob_path)],
    stdin=pigz_proc.stdout,
    stdout=subprocess.PIPE,
  )
  blob_sha256sum_proc = subprocess.Popen(
    ["sha256sum"],
    stdin=blob_tee_proc.stdout,
    stdout=subprocess.PIPE,
  )
  for proc in [tar_proc, diff_sha256sum_proc, diff_tee_proc, pigz_proc, blob_tee_proc, blob_sha256sum_proc]:
    if proc.wait() != 0:
      raise subprocess.CalledProcessError(returncode=proc.returncode, cmd=repr(proc.args))

  with open(out_path / "metadata.json", "w") as f:
    json.dump({
      "diff_digest": "sha256:" + diff_sha256sum_proc.stdout.read().decode("ascii").split()[0],
      "blob_digest": "sha256:" + blob_sha256sum_proc.stdout.read().decode("ascii").split()[0],
    }, f, separators=(",", ":"))


def subcmd_customise(args):
  in_path = pathlib.Path(getattr(args, "in"))
  out_path = pathlib.Path(args.out)
  with open(args.customisations) as f:
    customisations = json.load(f)

  manifest, config = select_and_load_manifest(in_path)

  (out_path / "diffs/sha256").mkdir(parents=True, exist_ok=True)
  for diff_digest in config["rootfs"]["diff_ids"]:
    diff_rel_path = diff_digest.replace(":", "/")
    (out_path / "diffs" / diff_rel_path).symlink_to(in_path / "diffs" / diff_rel_path)
  (out_path / "oci/blobs/sha256").mkdir(parents=True, exist_ok=True)
  for blob_ref in manifest["layers"]:
    blob_rel_path = blob_ref["digest"].replace(":", "/")
    (out_path / "oci/blobs" / blob_rel_path).symlink_to(in_path / "oci/blobs" / blob_rel_path)

  if customisations.get("newLayer"):
    new_layer_path = pathlib.Path(customisations["newLayer"])
    with open(new_layer_path / "metadata.json") as f:
      new_layer_metadata = json.load(f)

    (out_path / "diffs" / new_layer_metadata["diff_digest"].replace(":", "/")).symlink_to(new_layer_path / "diff")
    (out_path / "oci/blobs" / new_layer_metadata["blob_digest"].replace(":", "/")).symlink_to(new_layer_path / "blob")

    config["rootfs"]["diff_ids"].append(new_layer_metadata["diff_digest"])
    config["history"].append({"comment": "imgtool"})
    manifest["layers"].append({
      "mediaType": {
        "application/vnd.oci.image.manifest.v1+json": "application/vnd.oci.image.layer.v1.tar+gzip",
        "application/vnd.docker.distribution.manifest.v2+json": "application/vnd.docker.image.rootfs.diff.tar.gzip",
      }[manifest["mediaType"]],
      "digest": new_layer_metadata["blob_digest"],
      "size": (new_layer_path / "blob").stat().st_size,
    })

  for name, value in customisations.get("env", {}).items():
    env_list = config.setdefault("config", {}).get("Env", [])
    env_list = [x for x in env_list if not x.startswith(name + "=")]
    env_list.append(f"{name}={value}")
    config["config"]["Env"] = env_list
  if customisations.get("entrypoint") is not None:
    config["config"]["Entrypoint"] = customisations["entrypoint"]
  if customisations.get("cmd") is not None:
    config["config"]["Cmd"] = customisations["cmd"]

  new_config_blob = json.dumps(config, separators=(",", ":")).encode("utf-8")
  new_config_digest = "sha256:" + hashlib.sha256(new_config_blob).hexdigest()
  new_config_path = out_path / "oci/blobs" / new_config_digest.replace(":", "/")
  new_config_path.write_bytes(new_config_blob)
  log(f"new config: {new_config_path}")

  manifest["config"]["digest"] = new_config_digest
  manifest["config"]["size"] = len(new_config_blob)
  new_manifest_blob = json.dumps(manifest, separators=(",", ":")).encode("utf-8")
  new_manifest_digest = "sha256:" + hashlib.sha256(new_manifest_blob).hexdigest()
  new_manifest_path = out_path / "oci/blobs" / new_manifest_digest.replace(":", "/")
  new_manifest_path.write_bytes(new_manifest_blob)
  log(f"new manifest: {new_manifest_path}")

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
  post_fetch_parser.set_defaults(subcmd=subcmd_post_fetch)
  post_fetch_parser.add_argument("img_path")

  create_layer_parser = subparsers.add_parser("create-layer")
  create_layer_parser.set_defaults(subcmd=subcmd_create_layer)
  create_layer_parser.add_argument("customisations", metavar="JSON_PATH")
  create_layer_parser.add_argument("in", metavar="IMAGE_PATH")
  create_layer_parser.add_argument("out", metavar="IMAGE_PATH")

  customise_parser = subparsers.add_parser("customise")
  customise_parser.set_defaults(subcmd=subcmd_customise)
  customise_parser.add_argument("customisations", metavar="JSON_PATH")
  customise_parser.add_argument("in", metavar="IMAGE_PATH")
  customise_parser.add_argument("out", metavar="IMAGE_PATH")

  args = parser.parse_args()
  args.subcmd(args)


if __name__ == "__main__":
  main()
