#!/usr/bin/env nix-shell
#!nix-shell -E 'with import <nixpkgs> {}; mkShell { buildInputs = [(python3.withPackages (ps: with ps; [pillow requests]))]; }' -i python3

import argparse
import base64
import json
import mimetypes
import os
import pathlib
import requests
from PIL import Image

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--src", metavar="PATH", required=True)
  parser.add_argument("--dest", metavar="COLLECTION_ID", required=True)
  args = parser.parse_args()
  src_dir = pathlib.Path(args.src)

  user = login()

  with open(src_dir / "image_metadata.json", "r") as f:
    img_dicts = json.load(f)
  for img_dict in img_dicts:
    upload_image(img_dict, src_dir, args.dest, user)

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

def upload_image(img_dict, src_dir, dest_collection_id, user):
  img_path = src_dir / f"{img_dict['id']}.{img_dict['fileType']}"
  img_stat = img_path.stat()
  img = Image.open(img_path)
  req_payload = {
    "creatorUserId": user["localId"],
    "description": img_dict["description"],
    "isNSFW": img_dict["isNSFW"],
    "metadata": {
      "aspectRatio": img.width / img.height,
      "fileName": img_dict["originalFileName"],
      "height": img.height,
      "lastModified": int(img_stat.st_mtime * 1000),
      "size": img_stat.st_size,
      "type": mimetypes.guess_type(img_path)[0],
      "width": img.width,
    },
    "name": img_dict["name"],
    "parentCollectionId": dest_collection_id,
    "sourceName": img_dict["sourceName"],
    "sourceUrl": img_dict["sourceUrl"],
    "tags": img_dict["tags"],
    "thumbnailArrayBufferBase64": "",
    "transform": {
      "angle": 0,
      "brightness": 0,
      "contrast": 0,
      "crop": {
        "bottom": 1,
        "left": 0,
        "right": 1,
        "top": 0,
      },
      "flipX": False,
      "flipY": False,
      "saturation": 0,
      "scaleX": 0.5,
      "scaleY": 0.5,
    },
  }
  import pprint; pprint.pprint(req_payload)
  req_payload["arrayBufferBase64"] = base64.b64encode(img_path.read_bytes()).decode("ascii")
  resp = requests.post(
    f"https://prod.api.refern.app/image/{dest_collection_id}",
    json=req_payload,
    headers={
      "Authorization": user["idToken"],
      "Content-Type": "application/json",
    },
  )
  resp.raise_for_status()

if __name__ == "__main__":
  main()
