import datetime
import json
import os
import pathlib
import requests
import subprocess
import sys
import time

MAX_SNAPSHOT_AGE = datetime.timedelta(hours=12)

def main():
  download_dir = pathlib.Path(os.environ.get("TMPDIR", "/tmp"))
  staging_dir = pathlib.Path(os.environ["RESTIC_VIRTUAL_PATH"])

  download_dir.mkdir(parents=True, exist_ok=True)
  staging_dir.mkdir(parents=True, exist_ok=True)

  user = login()
  folders = {x["_id"]: x for x in get_folders(user)}
  folder_items = [{**item, "parentFolderId": folder_id} for folder_id in folders for item in get_folder_items(user, folder_id)]

  for folder_id, folder in folders.items():
    fullname = folder["name"].replace("/", "_")
    if folder["parentFolderId"]:
      fullname = folders[folder["parentFolderId"]]["__fullname"] + "/" + fullname
    folder["__fullname"] = fullname
  for item in folder_items:
    item["__fullname"] = folders[item["parentFolderId"]]["__fullname"] + "/" + item["name"].replace("/", "_")

  boards = [item for item in folder_items if item["type"] == "board"]
  collections = [item for item in folder_items if item["type"] == "collection"]

  for b in boards:
    log(f"board {b['_id']} \"{b['__fullname']}\": downloading...")
    board_data = get_board(user, b["_id"])
    board_dir = staging_dir / b["__fullname"]
    board_dir.mkdir(parents=True, exist_ok=True)
    with open(board_dir / "board.json", "w") as f:
      json.dump(board_data, f, separators=(',', ':'))

  export_statuses = {
    c["_id"]: get_export_status(user, c["_id"])
    for c in collections
  }

  for c in collections:
    xs = export_statuses[c["_id"]]
    if xs is None:
      log(f"collection {c['_id']} \"{c['__fullname']}\": has never been exported; initiating export")
      export_statuses[c["_id"]] = initiate_export(user, c["_id"])
    else:
      last_export = datetime.datetime.fromtimestamp(max(xs["exportTimes"]) / 1000, datetime.timezone.utc)
      age = datetime.datetime.now(tz=datetime.timezone.utc) - last_export
      if age > MAX_SNAPSHOT_AGE:
        log(f"collection {c['_id']} \"{c['__fullname']}\": last export was at {last_export}; initiating new export")
        delete_export(user, c["_id"], xs["_id"])
        export_statuses[c["_id"]] = initiate_export(user, c["_id"])
      else:
        log(f"collection {c['_id']} \"{c['__fullname']}\": using recent export from {last_export}")

  while True:
    pending_cids = [c["_id"] for c in collections if export_statuses[c["_id"]]["status"] != "completed"]
    if pending_cids:
      log("waiting for:")
      for cid in pending_cids:
        log(f"  {cid}: status={export_statuses[cid]['status']}")
      time.sleep(30)
      for cid in pending_cids:
        export_statuses[cid] = get_export_status(user, cid)
    else:
      break

  log("all exports ready for download")

  for c in collections:
    zip_path = download_dir / (c["_id"] + ".zip")
    extract_dir = staging_dir / c["__fullname"]
    extract_dir.mkdir(parents=True, exist_ok=True)
    log(f"collection {c['_id']} \"{c['__fullname']}\": downloading...")
    subprocess.run(
      ["curl", "--location", "--silent", "--show-error", "--fail", "--output", str(zip_path), export_statuses[c["_id"]]["downloadUrl"]],
      check=True,
    )
    log(f"collection {c['_id']} \"{c['__fullname']}\": extracting...")
    subprocess.run(
      ["unzip", str(zip_path)],
      cwd=str(extract_dir),
      check=True,
    )
    zip_path.unlink()

  log("restic upload...")
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

def login():
  """
  Returns {
    "localId": "...",  # user ID
    "idToken": "...",  # JWT used for future Authorization headers
    ...
  }
  """
  resp = requests.post(
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword",
    params={
      "key": os.environ["REFERN_IDENTITY_TOOLKIT_API_KEY"],
    },
    json={
      "clientType": "CLIENT_TYPE_WEB",
      "email": os.environ["REFERN_EMAIL"],
      "password": os.environ["REFERN_PASSWORD"],
      "returnSecureToken": True,
    },
    headers={
      "Content-Type": "application/json",
      "Origin": "https://my.refern.app",
    },
  )
  resp.raise_for_status()
  return resp.json()

def get_folders(user):
  """
  Returns [
    {
      "_id": "...",   # folder ID
      "name": "...",  # folder name
      ...
    },
    ...
  ]
  """
  resp = requests.get(
    f"https://prod.api.refern.app/folder/user/{user['localId']}",
    headers={
      "Authorization": user["idToken"],
      "Origin": "https://my.refern.app",
      "Referer": "https://my.refern.app",
    },
  )
  resp.raise_for_status()
  return resp.json()

def get_folder_items(user, folder_id):
  """
  Returns [
    {
      "_id": "...",   # collection/board ID
      "type": "collection" or "board",
      "name": "...",  # user-assigned collection/board name
    },
    ...
  ]
  """
  resp = requests.get(
    f"https://prod.api.refern.app/folder/{folder_id}/item",
    headers={
      "Authorization": user["idToken"],
      "Origin": "https://my.refern.app",
      "Referer": "https://my.refern.app",
    },
  )
  resp.raise_for_status()
  return resp.json()

def get_board(user, board_id):
  resp = requests.get(
    f"https://prod.api.refern.app/board/{board_id}",
    headers={
      "Authorization": user["idToken"],
      "Origin": "https://my.refern.app",
      "Referer": "https://my.refern.app",
    },
  )
  resp.raise_for_status()
  return resp.json()

def get_export_status(user, collection_id):
  """
  Returns {
    "status": "...",       # "started", "completed", "deleted" or perhaps other values
    "downloadUrl": "...",
    "exportTimes": [1746716902704, ...],
  }
  or returns None if collection hasn't been exported before.
  """
  resp = requests.get(
    f"https://prod.api.refern.app/collection/download/{collection_id}",
    headers={
      "Authorization": user["idToken"],
      "Origin": "https://my.refern.app",
      "Referer": "https://my.refern.app",
    },
  )
  if resp.status_code == 404:
    return None
  resp.raise_for_status()
  resp_json = resp.json()
  if resp_json["status"] not in ["started", "completed", "deleted"]:
    raise Exception(f"unexpected export status: {resp['status']}")
  return resp_json

def initiate_export(user, collection_id):
  """
  Returns same structure as get_export_status.
  """
  resp = requests.post(
    f"https://prod.api.refern.app/collection/download/{collection_id}",
    json={
      "collectionMetadataExportFileType": "json",
      "creatorUserId": user["localId"],
      "imageMetadataExportFileType": "json",
    },
    headers={
      "Authorization": user["idToken"],
      "Content-Type": "application/json",
      "Origin": "https://my.refern.app",
      "Referer": "https://my.refern.app",
    },
  )
  resp.raise_for_status()
  resp_json = resp.json()
  if resp_json["status"] not in ["started", "completed", "delete"]:
    raise Exception(f"unexpected export status: {resp['status']}")
  return resp_json

def delete_export(user, collection_id, export_id):
  resp = requests.delete(
    f"https://prod.api.refern.app/collection/download/{export_id}",
    headers={
      "Authorization": user["idToken"],
      "Origin": "https://my.refern.app",
      "Referer": "https://my.refern.app",
      "Resource-Id": collection_id,
      "Resource-Type": "collection",
    },
  )
  resp.raise_for_status()

def log(msg):
  print(msg, file=sys.stderr)

if __name__ == "__main__":
  main()
