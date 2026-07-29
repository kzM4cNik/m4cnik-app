#!/usr/bin/env python3
"""Upload all m4cnik-app sources to GitHub and trigger IPA build."""
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
ROOT = Path(__file__).resolve().parent

SKIP = {".git", "build", "Payload", "__pycache__", "xcodebuild.log"}
SKIP_EXT = {".pyc"}


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
            "User-Agent": "m4cnik-sync",
            **({"Content-Type": "application/json"} if body else {}),
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw.strip() else None
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", "replace")
        raise SystemExit(f"{method} {path} -> {e.code}: {err}") from e


def upload(token, rel, path: Path):
    content_b64 = base64.b64encode(path.read_bytes()).decode("ascii")
    sha = None
    try:
        existing = api("GET", f"/repos/{USER}/{REPO}/contents/{rel}?ref={BRANCH}", token)
        sha = existing.get("sha")
    except SystemExit as e:
        if "404" not in str(e):
            raise
    payload = {"message": f"Update {rel}", "content": content_b64, "branch": BRANCH}
    if sha:
        payload["sha"] = sha
    api("PUT", f"/repos/{USER}/{REPO}/contents/{rel}", token, payload)
    print("OK", rel)


def main():
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if not token:
        sys.exit("Set GITHUB_TOKEN env var")

    files = []
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(ROOT).as_posix()
        if any(p in SKIP for p in path.parts):
            continue
        if path.suffix in SKIP_EXT:
            continue
        files.append((rel, path))

    print(f"Uploading {len(files)} files...")
    for rel, path in files:
        upload(token, rel, path)

    api(
        "POST",
        f"/repos/{USER}/{REPO}/actions/workflows/build-ipa.yml/dispatches",
        token,
        {"ref": BRANCH},
    )
    print(f"Build triggered: https://github.com/{USER}/{REPO}/actions")


if __name__ == "__main__":
    main()
