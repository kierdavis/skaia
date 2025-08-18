# Based on https://github.com/AndrewOcamps/grafana-dashboard-backup/

import json
import os
import pathlib
import requests
import subprocess
import sys


def main():
  client = Client(
    url=os.environ["GRAFANA_URL"],
    token=os.environ["GRAFANA_TOKEN"],
  )

  staging_dir = pathlib.Path(os.environ["RESTIC_VIRTUAL_PATH"])
  staging_dir.mkdir(parents=True, exist_ok=True)

  for dash_ref in client.list_dashboards():
    if dash_ref.get("type") == "dash-folder":
      continue
    if dash_ref.get("folderTitle") == "Static":
      continue
    dash_path = staging_dir / f"{dash_ref['title']}.{dash_ref['uid']}.json"
    print(f"fetching {dash_path}...", file=sys.stderr)
    dash_data = client.get_dashboard(dash_ref["uid"])["spec"]
    with open(dash_path, "w") as f:
      json.dump(dash_data, f, separators=(",", ":"))

  print("restic upload...", file=sys.stderr)
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


class Client:
  def __init__(self, url, token):
    if not url.endswith("/"):
      url += "/"
    self.url = url
    self.auth_header = f"Bearer {token}"

  def list_dashboards(self):
    resp = requests.get(
      self.url + "api/search/",
      headers={"Authorization": self.auth_header},
    )
    resp.raise_for_status()
    return resp.json()

  def get_dashboard(self, uid):
    resp = requests.get(
      self.url + f"apis/dashboard.grafana.app/v1beta1/namespaces/default/dashboards/{uid}/dto",
      headers={"Authorization": self.auth_header},
    )
    resp.raise_for_status()
    return resp.json()


if __name__ == "__main__":
  main()
