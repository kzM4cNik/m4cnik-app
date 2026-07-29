#!/usr/bin/env python3
"""Upload build-ipa.yml and trigger workflow. Reads GITHUB_TOKEN from env."""
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
WORKFLOW_PATH = ".github/workflows/build-ipa.yml"
API = "https://api.github.com"

ROOT = Path(__file__).resolve().parent
WORKFLOW_LOCAL = ROOT / ".github" / "workflows" / "build-ipa.yml"


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


def main():
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if not token:
        sys.exit("GITHUB_TOKEN not set")

    if not WORKFLOW_LOCAL.is_file():
        sys.exit(f"Missing {WORKFLOW_LOCAL}")

    content = WORKFLOW_LOCAL.read_bytes()
    content_b64 = base64.b64encode(content).decode("ascii")

    sha = None
    try:
        existing = api("GET", f"/repos/{USER}/{REPO}/contents/{WORKFLOW_PATH}?ref={BRANCH}", token)
        sha = existing.get("sha")
        print("Workflow exists, updating...")
    except SystemExit as e:
        if "404" not in str(e):
            raise
        print("Creating workflow file...")

    payload = {
        "message": "Add GitHub Actions IPA build workflow",
        "content": content_b64,
        "branch": BRANCH,
    }
    if sha:
        payload["sha"] = sha

    api("PUT", f"/repos/{USER}/{REPO}/contents/{WORKFLOW_PATH}", token, payload)
    print(f"Uploaded {WORKFLOW_PATH}")

    print("Triggering workflow...")
    api(
        "POST",
        f"/repos/{USER}/{REPO}/actions/workflows/build-ipa.yml/dispatches",
        token,
        {"ref": BRANCH},
    )
    print(f"OK: https://github.com/{USER}/{REPO}/actions")


if __name__ == "__main__":
    main()
