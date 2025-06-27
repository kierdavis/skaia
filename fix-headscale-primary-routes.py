#!/usr/bin/env python3

import json
import subprocess

def main():
  routes = json.loads(subprocess.run(
    ["ssh", "root@headscale.skaia.cloud", "headscale routes list --output=json"],
    stdout=subprocess.PIPE,
    encoding="utf-8",
    check=True,
  ).stdout)

  routes = [r for r in routes if r.get("advertised")]

  routes_by_prefix = {}
  for route in routes:
    routes_by_prefix.setdefault(route["prefix"], []).append(route)

  bad_routes = []
  for prefix, alternative_routes in routes_by_prefix.items():
    if not any(r.get("is_primary") for r in alternative_routes):
      print(f"routes to {prefix} are advertised, but none of them are marked as primary")
      bad_routes.extend(alternative_routes)

  if not bad_routes:
    print("all ok")
    return

  print()
  print("will delete these routes from headscale, then restart the cni daemonset:")
  for route in bad_routes:
    print(f"  id={route['id']} node={route['node']['name']} prefix={route['prefix']} advertised={route.get('advertised', False)} enabled={route.get('enabled', False)} primary={route.get('is_primary', False)}")
  print()

  if input("proceed? (y/n) ") != "y":
    return

  for route in bad_routes:
    subprocess.run(["ssh", "root@headscale.skaia.cloud", f"headscale routes delete --route={route['id']}"], check=True)

  subprocess.run(["kubectl", "--context=skaia-node-direct", "--namespace=system", "rollout", "restart", "daemonset", "cni"], check=True)

if __name__ == "__main__":
  main()
