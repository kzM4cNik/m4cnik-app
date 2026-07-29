#!/usr/bin/env python3
import json
import os
import sys
import time
import urllib.request

USER = "Foxcoc"
REPO = "m4cnik-app"
API = "https://api.github.com"


def api(path):
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    req = urllib.request.Request(
        API + path,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "wait-ipa",
        },
    )
    with urllib.request.urlopen(req, timeout=90) as resp:
        return json.loads(resp.read().decode())


def main():
    if not os.environ.get("GITHUB_TOKEN", "").strip():
        sys.exit("GITHUB_TOKEN not set")

    run = None
    for i in range(80):
        runs = api(f"/repos/{USER}/{REPO}/actions/runs?per_page=1")
        run = runs["workflow_runs"][0]
        print(
            f"[{i + 1}] run {run['id']} status={run['status']} "
            f"conclusion={run.get('conclusion')} url={run['html_url']}"
        )
        if run["status"] == "completed":
            break
        time.sleep(15)

    if not run or run.get("conclusion") != "success":
        jobs = api(f"/repos/{USER}/{REPO}/actions/runs/{run['id']}/jobs")
        for job in jobs.get("jobs", []):
            print("JOB", job["name"], job["status"], job.get("conclusion"))
        sys.exit(f"Build failed: {run.get('html_url')}")

    arts = api(f"/repos/{USER}/{REPO}/actions/runs/{run['id']}/artifacts")
    items = arts.get("artifacts", [])
    if not items:
        sys.exit("No artifacts found")

    for art in items:
        print(
            f"ARTIFACT {art['name']} id={art['id']} "
            f"size={art['size_in_bytes']} expires={art['expires_at']}"
        )

    print(f"DOWNLOAD_PAGE {run['html_url']}")
    print(f"ARTIFACTS_PAGE https://github.com/{USER}/{REPO}/actions/runs/{run['id']}")


if __name__ == "__main__":
    main()
