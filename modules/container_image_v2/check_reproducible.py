#!/usr/bin/env nix-shell
#!nix-shell -p diffoci -p gnutar -p podman -p python3 -i python3

import contextlib
import pathlib
import re
import subprocess
import sys
import tempfile

image_src = sys.argv[1]
this_script = pathlib.Path(__file__)

nix_derivation_gcroot_path = pathlib.Path("check_reproducible_drv.gcroot")

nix_derivation = subprocess.run(
  ["nix-instantiate", str(this_script.parent / "image.nix"), "-I", f"src={image_src}", "--add-root", str(nix_derivation_gcroot_path)],
  stdout=subprocess.PIPE,
  check=True,
).stdout.decode("utf-8").strip()


def build_it():
  nix_store_path = pathlib.Path(subprocess.run(
    ["nix-store", "--realise", nix_derivation],
    stdout=subprocess.PIPE,
    check=True,
  ).stdout.decode("utf-8").strip())

  oci_dir_path = nix_store_path / "oci"

  tar_proc = subprocess.Popen(
    ["tar", "--create", "--dereference", f"--directory={oci_dir_path}", "."],
    stdout=subprocess.PIPE,
  )
  podman_load_proc = subprocess.Popen(
    ["podman", "load"],
    stdin=tar_proc.stdout,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
  )
  for proc in [tar_proc, podman_load_proc]:
    if proc.wait() != 0:
      sys.stderr.write(podman_load_proc.stdout.read().decode("utf-8"))
      raise subprocess.CalledProcessError(returncode=proc.returncode, cmd=repr(proc.args))

  return re.search(r"\bLoaded image: sha256:(\w+)\b", podman_load_proc.stdout.read().decode("utf-8")).group(1)


@contextlib.contextmanager
def temporary_podman_tag(image_id):
  tag = f"docker.io/dummy/dummy:{image_id}"
  subprocess.run(
    ["podman", "tag", image_id, tag],
    check=True,
  )
  try:
    yield tag
  finally:
    subprocess.run(
      ["podman", "untag", tag],
    )


podman_id_1 = build_it()
subprocess.run(["nix-collect-garbage"], check=True)
podman_id_2 = build_it()

nix_derivation_gcroot_path.unlink()

if podman_id_1 == podman_id_2:
  print()
  print("Image is binary-reproducible.")
  raise SystemExit(0)

with temporary_podman_tag(podman_id_1) as podman_tag_1, \
     temporary_podman_tag(podman_id_2) as podman_tag_2:

  subprocess.run(
    ["diffoci", "diff", f"podman://{podman_tag_1}", f"podman://{podman_tag_2}"],
    check=True,
  )
