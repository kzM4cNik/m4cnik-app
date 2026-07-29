#!/usr/bin/env python3
"""Upload one file to GitHub repo via API."""
import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

USER = "Foxcoc"
REPO = "m4cnik-app"
BRANCH = "main"
API = "https://api.github.com"


def api(method, path, token, data=None):
    body = json.dumps(data).encode("utf-8") if data is not None else None
    req = urllib.request.Request(
        API + path,
        data=body,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "m4cnik-deploy",
            **({"Content-Type": "application/json"} if body else {}),
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw.strip() else None
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", "replace")
        raise SystemExit(f"API {method} {path} -> {e.code}: {err}") from e


def upload_file(token, repo_path, local_path, message):
    content_b64 = base64.b64encode(Path(local_path).read_bytes()).decode("ascii")
    sha = None
    try:
        existing = api("GET", f"/repos/{USER}/{REPO}/contents/{repo_path}?ref={BRANCH}", token)
        sha = existing.get("sha")
    except SystemExit as e:
        if "404" not in str(e):
            raise
    payload = {"message": message, "content": content_b64, "branch": BRANCH}
    if sha:
        payload["sha"] = sha
    api("PUT", f"/repos/{USER}/{REPO}/contents/{repo_path}", token, payload)
    print(f"OK {repo_path}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("repo_path")
    p.add_argument("local_path")
    p.add_argument("--message", default="Update file")
    args = p.parse_args()
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if not token:
        sys.exit("GITHUB_TOKEN not set")
    upload_file(token, args.repo_path, args.local_path, args.message)


if __name__ == "__main__":
    main()
