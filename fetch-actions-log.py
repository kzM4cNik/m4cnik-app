#!/usr/bin/env python3
import io
import json
import os
import sys
import time
import zipfile

import requests

USER = "Foxcoc"
REPO = "m4cnik-app"
token = os.environ.get("GITHUB_TOKEN", "").strip()
if not token:
    sys.exit("GITHUB_TOKEN not set")

h = {
    "Authorization": f"Bearer {token}",
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
}

for _ in range(15):
    runs = requests.get(
        f"https://api.github.com/repos/{USER}/{REPO}/actions/runs?per_page=1",
        headers=h,
        timeout=60,
    ).json()
    run = runs["workflow_runs"][0]
    print("run", run["id"], run["status"], run["conclusion"], run["html_url"])
    if run["status"] == "completed":
        break
    time.sleep(15)

jobs = requests.get(
    f"https://api.github.com/repos/{USER}/{REPO}/actions/runs/{run['id']}/jobs",
    headers=h,
    timeout=60,
).json()
job = jobs["jobs"][0]
log = requests.get(
    f"https://api.github.com/repos/{USER}/{REPO}/actions/jobs/{job['id']}/logs",
    headers=h,
    allow_redirects=True,
    timeout=120,
)
print("log status", log.status_code, "bytes", len(log.content))
if log.content[:2] == b"PK":
    z = zipfile.ZipFile(io.BytesIO(log.content))
    for name in z.namelist():
        txt = z.read(name).decode("utf-8", "replace")
        if any(k in txt for k in ("xcodebuild", "Show build log", "BUILD FAILED", "##[error]")):
            print("\n===== ", name, " =====")
            for line in txt.splitlines()[-180:]:
                print(line)
else:
    print(log.text[-8000:])
