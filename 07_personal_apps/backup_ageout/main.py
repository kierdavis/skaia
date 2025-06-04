import bisect
import datetime
import json
import subprocess
import sys

NOW = datetime.datetime.now(tz=datetime.timezone.utc)

def main():
  snaps = json.loads(subprocess.run(["restic", "snapshots", "--json"], check=True, stdout=subprocess.PIPE).stdout)
  snaps = [s for s in snaps if "auto" in s.get("tags", [])]
  for snap in snaps:
    snap["time"] = datetime.datetime.fromisoformat(snap["time"])
  snaps.sort(key=lambda s: s["time"])

  snaps_by_path = {}
  for snap in snaps:
    [path] = snap["paths"]
    snaps_by_path.setdefault(path, []).append(snap)

  to_forget = []
  for path, snap_set in snaps_by_path.items():
    to_forget.extend(ageout(snap_set, path))

  if not to_forget:
    print("nothing to delete")
    return

  if "--force" in sys.argv[1:]:
    print("restic forget...")
    while to_forget:
      batch, to_forget = to_forget[:100], to_forget[100:]
      subprocess.run(["restic", "forget"] + [s["id"] for s in batch], check=True)
    print("all done")
  else:
    print("restic forget skipped because --force not specified")

def ageout(snaps, path):
  n_snaps = len(snaps)

  # Keep the newest snapshot in all circumstances.
  snaps, to_keep = snaps[:-1], snaps[-1:]

  # Keep any other snapshots from the last 24 hours, or from the future.
  keep_all_after = NOW - datetime.timedelta(days=1)
  split_at = bisect.bisect_left(snaps, keep_all_after, key=lambda s: s["time"])
  snaps, more_to_keep = snaps[:split_at], snaps[split_at:]
  to_keep = more_to_keep + to_keep

  to_forget = []
  window_end = keep_all_after
  window_durations_iter = window_durations()
  while snaps:
    window_start = window_end - next(window_durations_iter)
    split_at = bisect.bisect_left(snaps, window_start, key=lambda s: s["time"])
    snaps, window = snaps[:split_at], snaps[split_at:]
    # Keep the oldest snapshot in the window.
    to_keep = window[:1] + to_keep
    to_forget = window[1:] + to_forget
    window_end = window_start

  assert len(to_keep) + len(to_forget) == n_snaps

  if to_forget:
    print(f"{path}:")
    print("  keep:")
    for snap in to_keep:
      print(f"    {snap['id']} @ {snap['time']}")
    print("  forget:")
    for snap in to_forget:
      print(f"    {snap['id']} @ {snap['time']}")
    print()

  return to_forget

def window_durations():
  # (Keep all snapshots from the last 24 hours, or from the future.)
  # Keep at most one snapshot per day for the 3 days before that.
  for _ in range(3):
    yield datetime.timedelta(days=1)
  # Keep at most one snapshot per week for the 4 weeks before that.
  for _ in range(4):
    yield datetime.timedelta(days=7)
  # Keep at most one snapshot per month for the 12 months before that.
  for _ in range(12):
    yield datetime.timedelta(days=28)
  # Keep at most one snapshot per quarter for the rest of history:
  while True:
    yield datetime.timedelta(days=84)

if __name__ == "__main__":
  main()
