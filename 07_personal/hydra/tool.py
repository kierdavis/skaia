#!/usr/bin/env nix-shell
#!nix-shell -E 'with import <nixpkgs> {}; mkShell { packages = [(python3.withPackages (py: with py; [beautifulsoup4 tabulate]))]; }' -i python3

import argparse
import getpass
import html
import re
import sys
from bs4 import BeautifulSoup, Tag
from dataclasses import dataclass
from tabulate import tabulate
from urllib.parse import urlencode
from urllib.request import Request, urlopen

BASE_URL = "http://hydra.personal.svc.kube.skaia.cloud"

def at(idx, it):
  try:
    it = iter(it)
    for i in range(idx):
      next(it)
    return next(it)
  except StopIteration:
    raise IndexError(i) from None

@dataclass(frozen=True)
class Home:
  proj_names: frozenset

  @classmethod
  def fetch(cls):
    with urlopen(BASE_URL) as resp:
      soup = BeautifulSoup(resp, "html.parser")
    return cls(
      proj_names = frozenset(
        tag.string
        for tag in soup.find_all(href=re.compile("^http://[^/]+/project/[^/]+$"))
      ),
    )

@dataclass(frozen=True)
class Project:
  jobset_names: frozenset

  @classmethod
  def fetch(cls, name):
    with urlopen(f"{BASE_URL}/project/{name}") as resp:
      soup = BeautifulSoup(resp, "html.parser")
    return cls(
      jobset_names = frozenset(
        tag.string
        for tag in soup.find_all(href=re.compile(r"^http://[^/]+/jobset/[^/]+/[^/]+$"))
      ),
    )

@dataclass(frozen=True)
class Jobset:
  enabled: bool
  eval_running_since: str
  last_eval_has_errors: bool # None means never evaluated

  @classmethod
  def fetch(cls, proj_name, jobset_name):
    with urlopen(f"{BASE_URL}/jobset/{proj_name}/{jobset_name}") as resp:
      soup = BeautifulSoup(resp, "html.parser")
    return cls(
      enabled = cls._get_enabled(soup),
      eval_running_since = cls._get_eval_running_since(soup),
      last_eval_has_errors = cls._get_last_eval_has_errors(soup),
    )

  @staticmethod
  def _get_enabled(soup):
    div = soup.find("div", id="tabs-configuration")
    th = soup.find("th", string="State:")
    td = th.find_next_sibling("td")
    return td.string.lower() != "disabled"

  @staticmethod
  def _get_eval_running_since(soup):
    th = soup.find("th", string="Evaluation running since:")
    if th is None:
      return None
    td = th.find_next_sibling("td")
    return td.string

  @staticmethod
  def _get_last_eval_has_errors(soup):
    div = soup.find("div", id="tabs-evaluations")
    try:
      table = at(1, div.find_all("table"))
    except IndexError:
      return None
    tbody = table.find("tbody")
    td = at(2, tbody.find_all("td"))
    return td.find("span", class_="badge-warning") is not None

@dataclass(frozen=True)
class JobsetJobs:
  jobs: dict # {"job_name": Job(...)}

  @classmethod
  def fetch(cls, proj_name, jobset_name):
    with urlopen(f"{BASE_URL}/jobset/{proj_name}/{jobset_name}/jobs-tab") as resp:
      soup = BeautifulSoup(resp, "html.parser")
    return cls(
      jobs = {
        tr.find("th").string: Job._parse_tr(tr)
        for tr in soup.find("tbody").find_all("tr")
        if tr.find("td").contents # first td is non-empty iff job is defined in the latest eval
      },
    )

hydra_session = None
def get_cookie():
  global hydra_session
  if hydra_session is None:
    hydra_session = getpass.getpass("Input hydra_session: ")
  return f"hydra_session={hydra_session}"

def trigger_evaluation(proj_name, jobset_name):
  print(f"triggering evaluation of {proj_name}/{jobset_name}...", end=" ")
  query = urlencode({"jobsets": f"{proj_name}:{jobset_name}", "force": "1"})
  query = html.escape(query, quote=False) # yeah???
  with urlopen(Request(
    f"{BASE_URL}/api/push?{query}",
    method="POST",
    headers={
      "Cookie": get_cookie(),
      "Content-Length": "0",
      "Origin": BASE_URL,
      "Referer": BASE_URL,
    },
  )) as resp:
    print("ok")

def restart_build(build_id, *, comment=""):
  print(f"restarting build {build_id} ({comment})...", end=" ")
  with urlopen(Request(
    f"{BASE_URL}/build/{build_id}/restart",
    headers={"Cookie": get_cookie()},
  )) as resp:
    print("ok")

@dataclass(frozen=True)
class Job:
  last_build_id: str
  last_build_status: str  # "succeeded", "queued", "aborted", "dependency failed", etc

  @classmethod
  def _parse_tr(cls, tr):
    a = tr.find("td").find("a")
    return cls(
      last_build_id = a["href"].split("/")[-1],
      last_build_status = a.find("img")["alt"].lower(),
    )

def cmd_evals(args):
  home = Home.fetch()
  table_data = []
  for proj_name in sorted(home.proj_names):
    try:
      proj = Project.fetch(proj_name)
      for jobset_name in sorted(proj.jobset_names):
        try:
          jobset = Jobset.fetch(proj_name, jobset_name)
          if not jobset.enabled:
            continue
          if jobset.eval_running_since is not None:
            eval_status = "running since " + jobset.eval_running_since
          elif jobset.last_eval_has_errors is None:
            eval_status = "never evaluated"
          elif jobset.last_eval_has_errors:
            eval_status = "errors"
          else:
            eval_status = "ok"
          table_data.append((proj_name, jobset_name, eval_status))
        except Exception:
          print(f"(in jobset {jobset_name})", file=sys.stderr)
          raise
    except Exception:
      print(f"(in project {proj_name})", file=sys.stderr)
      raise
  print(tabulate(table_data, headers=("Project", "Jobset", "Eval status")))

def cmd_builds(args):
  home = Home.fetch()
  table_data = []
  for proj_name in sorted(home.proj_names):
    try:
      proj = Project.fetch(proj_name)
      for jobset_name in sorted(proj.jobset_names):
        try:
          jobset = Jobset.fetch(proj_name, jobset_name)
          if not jobset.enabled:
            continue
          jobs = JobsetJobs.fetch(proj_name, jobset_name)
          for job_name, job in jobs.jobs.items():
            table_data.append((proj_name, jobset_name, job_name, job.last_build_status))
        except Exception:
          print(f"(in jobset {jobset_name})", file=sys.stderr)
          raise
    except Exception:
      print(f"(in project {proj_name})", file=sys.stderr)
      raise
  print(tabulate(table_data, headers=("Project", "Jobset", "Job", "Build status")))

def cmd_retry_evals(args):
  limit = args.limit
  home = Home.fetch()
  for proj_name in sorted(home.proj_names):
    try:
      proj = Project.fetch(proj_name)
      for jobset_name in sorted(proj.jobset_names):
        try:
          jobset = Jobset.fetch(proj_name, jobset_name)
          if not jobset.enabled:
            continue
          if jobset.eval_running_since is not None:
            continue
          if not args.succeeded and job.last_eval_has_errors is False:
            continue
          if limit is not None:
            if limit == 0:
              return
            limit -= 1
          trigger_evaluation(proj_name, jobset_name)
        except Exception:
          print(f"(in jobset {jobset_name})", file=sys.stderr)
          raise
    except Exception:
      print(f"(in project {proj_name})", file=sys.stderr)
      raise

def cmd_retry_builds(args):
  limit = args.limit
  home = Home.fetch()
  for proj_name in sorted(home.proj_names):
    try:
      proj = Project.fetch(proj_name)
      for jobset_name in sorted(proj.jobset_names):
        try:
          jobset = Jobset.fetch(proj_name, jobset_name)
          if not jobset.enabled:
            continue
          jobs = JobsetJobs.fetch(proj_name, jobset_name)
          for job_name, job in jobs.jobs.items():
            try:
              if job.last_build_status == "queued":
                continue
              if not args.succeeded and job.last_build_status == "succeeded":
                continue
              if limit is not None:
                if limit == 0:
                  return
                limit -= 1
              restart_build(job.last_build_id, comment=f"{proj_name}/{jobset_name}/{job_name}")
            except Exception:
              print(f"(in job {job_name})", file=sys.stderr)
              raise
        except Exception:
          print(f"(in jobset {jobset_name})", file=sys.stderr)
          raise
    except Exception:
      print(f"(in project {proj_name})", file=sys.stderr)
      raise

def main():
  parser = argparse.ArgumentParser()
  subparsers = parser.add_subparsers(required=True)
  evals_parser = subparsers.add_parser("evals")
  evals_parser.set_defaults(cmd=cmd_evals)
  builds_parser = subparsers.add_parser("builds")
  builds_parser.set_defaults(cmd=cmd_builds)
  retry_evals_parser = subparsers.add_parser("retry-evals")
  retry_evals_parser.set_defaults(cmd=cmd_retry_evals)
  retry_evals_parser.add_argument("--succeeded", action="store_true")
  retry_evals_parser.add_argument("--limit", action="store", type=int)
  retry_builds_parser = subparsers.add_parser("retry-builds")
  retry_builds_parser.set_defaults(cmd=cmd_retry_builds)
  retry_builds_parser.add_argument("--succeeded", action="store_true")
  retry_builds_parser.add_argument("--limit", action="store", type=int)
  args = parser.parse_args()
  args.cmd(args)

if __name__ == "__main__":
  main()
