#!/usr/bin/env nix-shell
#!nix-shell -p curl parted python3 util-linux xz -i python3

import argparse
import json
import subprocess
from shlex import quote

flavour_urls = {
  %{ for flav_name, flav in flavours }
  "${flav_name}": "https://factory.talos.dev/image/${flav.schematic_id}/v${flav.version}/metal-amd64.raw.xz",
  %{ endfor }
}

def log_and_run(cmd, **kwargs):
  print("** " + " ".join(quote(word) for word in cmd))
  return subprocess.run(cmd, **kwargs)

def describe_disk(dev):
  return json.loads(subprocess.run(
    ["parted", dev, "unit", "s", "print", "--json"],
    check=True,
    stdin=subprocess.DEVNULL,
    stdout=subprocess.PIPE,
    encoding="utf-8",
  ).stdout)["disk"]

def size_str_to_sectors(s):
  assert s.endswith("s")
  return int(s[:-1])

def size_sectors_to_str(n):
  return f"{n}s"

def part_device(disk_dev, part_number):
  if disk_dev[-1].isdigit():
    return f"{disk_dev}p{part_number}"
  else:
    return f"{disk_dev}{part_number}"

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--target", metavar="BLOCKDEV", required=True)
  parser.add_argument("--flavour", metavar="FLAVOUR", required=True)
  args = parser.parse_args()

  print("Partition table before:")
  subprocess.run(
    ["parted", args.target, "unit", "s", "print"],
    check=True,
    stdin=subprocess.DEVNULL,
  )
  print()
  print()

  disk = describe_disk(args.target)
  sector_size = disk["logical-sector-size"]
  assert disk["physical-sector-size"] == sector_size
  sector_align = 4

  preserve_parts = [p for p in disk["partitions"] if p["name"].startswith("OSD")]
  is_part_number_preserved = lambda n: any(p["number"] == n for p in preserve_parts)
  if preserve_parts:
    print("Will preserve these partitions:")
    for part in preserve_parts:
      print(f"  {part['name']}: {part['start']}s .. {part['end']}s")
  else:
    print("Will not preserve any partitions.")
  print()

  if input("Proceed? (y/n) ") != "y":
    raise SystemExit(1)

  if preserve_parts:
    for part in disk["partitions"]:
      if not is_part_number_preserved(part["number"]):
        log_and_run(["wipefs", "--all", part_device(args.target, part["number"])], check=True)
        log_and_run(["blkdiscard", "--force", part_device(args.target, part["number"])], check=True)
  else:
    for part in disk["partitions"]:
      log_and_run(["wipefs", "--all", part_device(args.target, part["number"])], check=True)
    log_and_run(["wipefs", "--all", args.target], check=True)
    log_and_run(["blkdiscard", "--force", args.target], check=True)

  dd_last_sector = size_str_to_sectors(disk["size"]) - 1
  for part in preserve_parts:
    dd_last_sector = min(dd_last_sector, size_str_to_sectors(part["start"]) - 1)
  pipeline = f"curl --fail --location {quote(flavour_urls[args.flavour])} | xzcat | dd of={quote(args.target)} bs={sector_size} count={dd_last_sector+1}"
  log_and_run(["sh", "-c", pipeline], check=True)

  log_and_run(["parted", "---pretend-input-tty", args.target, "print"], check=True, input=b"fix\n")

  disk = describe_disk(args.target)
  assert disk["logical-sector-size"] == sector_size
  assert disk["physical-sector-size"] == sector_size

  if preserve_parts:
    for preserve_part in preserve_parts:
      log_and_run(["parted", args.target, "mkpart", preserve_part["name"], size_sectors_to_str(preserve_part["start"]), size_sectors_to_str(preserve_part["end"])])
      disk = describe_disk(args.target)
      [new_part] = [p for p in disk["partitions"] if p["name"] == preserve_part["name"]]
      log_and_run(["parted", args.target, "type", str(new_part["number"]), preserve_part["type-uuid"]])

  else:
    unalloc_start_sector = max(size_str_to_sectors(p["end"]) for p in disk["partitions"]) + 1
    unalloc_start_sector = ((unalloc_start_sector + sector_align - 1) // sector_align) * sector_align
    osd_start_sector = unalloc_start_sector + (50*1024*1024*1024) // sector_size
    osd_start_sector = ((osd_start_sector + sector_align - 1) // sector_align) * sector_align
    gpt_mirror_start_sector = size_sectors_to_str(disk["size"]) - 33
    gpt_mirror_start_sector = (gpt_mirror_start_sector // sector_align) * sector_align
    if gpt_mirror_start_sector - osd_start_sector >= (10*1024*1024*1024)//sector_size:
      osd_end_sector = gpt_mirror_start_sector - 1
      log_and_run(["parted", args.target, "mkpart", "OSD0", size_sectors_to_str(osd_start_sector), size_sectors_to_str(osd_end_sector)])
      disk = describe_disk(args.target)
      [new_part] = [p for p in disk["partitions"] if p["name"] == "OSD0"]
      log_and_run(["parted", args.target, "type", str(new_part["number"]), "4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D"])
    else:
      print("not enough free space to create an OSD")

  print()
  print()
  print("Partition table after:")
  subprocess.run(
    ["parted", args.target, "unit", "s", "print"],
    check=True,
    stdin=subprocess.DEVNULL,
  )
  print()
  subprocess.run(
    ["sh", "-c", f"blkid {quote(args.target)}* | sort"],
    check=True,
    stdin=subprocess.DEVNULL,
  )

if __name__ == "__main__":
  main()
