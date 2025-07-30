import datetime
import json
import os
import pathlib
import pprint
import requests
import subprocess
import sys
import uuid


def main():
  client = SyncClient(
    auth_token=os.environ["TODOIST_API_TOKEN"],
    resource_types={"items"},
  )
  backup(client)
  adjust_past_dates(client)
  client.sync()


def backup(client):
  print("restic...", file=sys.stderr)
  staging_dir = pathlib.Path(os.environ["RESTIC_VIRTUAL_PATH"])
  staging_dir.mkdir(parents=True, exist_ok=True)
  for resource_type in client.resource_types:
    with open(staging_dir / f"{resource_type}.json", "w") as f:
      json.dump(client[resource_type], f, separators=(',', ':'))
  subprocess.run(
    [
      "restic",
      "backup",
      "--exclude=lost+found",
      "--host=generic",
      "--one-file-system",
      "--read-concurrency=4",
      "--tag=auto",
      str(staging_dir),
    ],
    check=True,
  )
  print(file=sys.stderr)


def adjust_past_dates(client):
  today = datetime.date.today()
  for task in client["items"].values():
    if task["due"] is None:
      continue
    due_date = datetime.date.fromisoformat(task["due"]["date"])
    if task["due"]["is_recurring"]:
      if due_date < today:
        task["due"]["date"] = today.isoformat()
        client.queue({
          "type": "item_update",
          "args": {
            "id": task["id"],
            "due": task["due"],
          },
          "uuid": str(uuid.uuid4()),
        })
    else:
      if due_date <= today:
        client.queue({
          "type": "item_update",
          "args": {
            "id": task["id"],
            "due": None,
          },
          "uuid": str(uuid.uuid4()),
        })


class SyncClient:
  def __init__(self, auth_token, resource_types):
    self.auth_token = auth_token
    self.resource_types = resource_types
    self.sync_token = "*"
    self.cmds = []
    self.resources = {}
    self.sync()

  def sync(self):
    print(f"sync with command(s):", file=sys.stderr)
    pprint.pp(self.cmds, sys.stderr)

    resp = requests.post(
      "https://api.todoist.com/api/v1/sync",
      headers={"Authorization": f"Bearer {self.auth_token}"},
      data={
        "sync_token": self.sync_token,
        "resource_types": json.dumps(list(self.resource_types), separators=(',', ':')),
        "commands": json.dumps(self.cmds, separators=(',', ':')),
      },
    )
    resp.raise_for_status()
    resp = resp.json()
    self.sync_token = resp.pop("sync_token")
    resp.pop("full_sync_date_utc", None)

    sync_status = resp.pop("sync_status", {})
    failed_cmds = []
    error_msg = ""
    for cmd in self.cmds:
      status = sync_status[cmd["uuid"]]
      if status != "ok":
        failed_cmds.append(cmd)
        error_msg += f"\n{cmd['type']} {cmd['args']} -> {status}"
    print(f"{len(self.cmds)-len(failed_cmds)} of {len(self.cmds)} command(s) succeeded", file=sys.stderr)
    self.cmds = failed_cmds
    if error_msg:
      raise CommandError("one or more command(s) failed:" + error_msg)

    resp.pop("temp_id_mapping", None)  # TODO

    if resp.pop("full_sync", False):
      self.resources = {}
    for resource_type, resource_list in resp.items():
      print(f"got {len(resource_list)} {resource_type}", file=sys.stderr)
      for resource in resource_list:
        self.resources.setdefault(resource_type, {})[resource["id"]] = resource

    print("sync complete", file=sys.stderr)
    print(file=sys.stderr)

  def queue(self, *cmds):
    self.cmds.extend(cmds)

  def __getitem__(self, resource_type):
    return self.resources[resource_type]


class CommandError(Exception):
  pass


if __name__ == "__main__":
  main()
