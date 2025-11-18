import datetime
import http.server
import json
import os
import requests
import ssl

def query_todoist():
  params = {"query": "no date | today | date before: today", "limit": "200"}
  headers = {"Authorization": f"Bearer {os.environ['TODOIST_API_TOKEN']}"}
  while True:
    resp = requests.get(
      "https://api.todoist.com/api/v1/tasks/filter",
      params=params,
      headers=headers,
    )
    resp.raise_for_status()
    resp = resp.json()
    yield from resp["results"]
    if resp.get("next_cursor") is not None:
      params["cursor"] = resp["next_cursor"]
    else:
      break

def partition_by_has_deadline(tasks):
  with_deadline, without_deadline = [], []
  for task in tasks:
    if task["deadline"] is not None:
      with_deadline.append(task)
    else:
      without_deadline.append(task)
  return with_deadline, without_deadline

def sort_key(task):
  return (
    datetime.date.fromisoformat(task["deadline"]["date"]) if task["deadline"] is not None else None,
    -task["priority"],
    -datetime.datetime.fromisoformat(task["updated_at"]).timestamp(),
  )

def format_deadline(task):
  if task["deadline"] is None:
    return None
  s = task["deadline"]["date"]
  d = datetime.date.fromisoformat(s)
  n = (d - datetime.date.today()).days
  if n < -1:
    return f"{-n} days ago"
  elif n == -1:
    return "yesterday"
  elif n == 0:
    return "today"
  elif n == 1:
    return "tomorrow"
  elif n <= 7:
    return d.strftime("%A")
  elif n <= 365:
    return d.strftime("%d %b")
  else:
    return s

def format_tasks(tasks):
  return [
    {
      "content": task["content"],
      # https://usetrmnl.com/framework/item#with-meta-emphasis
      "emphasis": {
        1: 1, # "p4"
        2: 1, # "p3"
        3: 2, # "p2"
        4: 3, # "p1"
      }[task["priority"]],
      "deadline": format_deadline(task),
    }
    for task in tasks
  ]

class RequestHandler(http.server.BaseHTTPRequestHandler):
  def do_GET(self):
    if self.headers.get("Authorization", "") != "Bearer " + os.environ["TRMNL_PRIVATE_PLUGIN_AUTH_TOKEN"]:
      self.send_error(401)
      return

    with_deadline, without_deadline = partition_by_has_deadline(query_todoist())
    with_deadline.sort(key=sort_key)
    without_deadline.sort(key=sort_key)

    body = json.dumps(
      {
        "task_lists": [
          {"title": "Due soon", "tasks": format_tasks(with_deadline)},
          {"title": "Any time", "tasks": format_tasks(without_deadline)},
        ],
      },
      separators=(',', ':'),
    ).encode("utf-8")

    self.send_response(200)
    self.send_header("Content-Type", "application/json")
    self.send_header("Content-Length", len(body))
    self.end_headers()
    self.wfile.write(body)

  def address_string(self):
    val = self.headers.get("X-Forwarded-For")
    if val:
      return val
    return super().address_string()

def main():
  server = http.server.HTTPServer(("", 443), RequestHandler)
  ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
  ctx.load_cert_chain(certfile=os.environ["TLS_CERT"], keyfile=os.environ["TLS_KEY"])
  server.socket = ctx.wrap_socket(server.socket, server_side=True)
  server.serve_forever()

if __name__ == "__main__":
  main()
