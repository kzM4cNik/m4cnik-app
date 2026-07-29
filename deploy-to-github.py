#!/usr/bin/env python3
"""
Upload m4cnik-app to GitHub and trigger IPA build.
Usage (PowerShell):
  $env:GITHUB_TOKEN = "ghp_xxxx"
  python deploy-to-github.py --user YOUR_GITHUB_USERNAME --repo m4cnik-app
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
API = "https://api.github.com"

SKIP_DIRS = {".git", "build", "__pycache__", "Payload"}
SKIP_FILES = {".DS_Store"}


def api(method: str, path: str, token: str, data: dict | None = None) -> dict | list | None:
    url = API + path if path.startswith("/") else path
    body = None
    if data is not None:
        body = json.dumps(data).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=body,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "m4cnik-deploy",
        },
    )
    if body is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw.strip() else None
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", "replace")
        raise SystemExit(f"GitHub API {method} {path} -> {e.code}: {err}") from e


def collect_files() -> list[tuple[str, Path]]:
    out: list[tuple[str, Path]] = []
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(ROOT)
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        if path.name in SKIP_FILES:
            continue
        out.append((rel.as_posix(), path))
    return out


def ensure_repo(user: str, repo: str, token: str, private: bool) -> str:
    try:
        info = api("GET", f"/repos/{user}/{repo}", token)
        print(f"Repo exists: {info['html_url']}")
        return info["default_branch"]
    except SystemExit as e:
        if "404" not in str(e):
            raise
    print(f"Creating repo {user}/{repo}...")
    info = api(
        "POST",
        "/user/repos",
        token,
        {
            "name": repo,
            "description": "M4cNik rulit — minimal iOS app, cloud IPA build",
            "private": private,
            "auto_init": False,
        },
    )
    print(f"Created: {info['html_url']}")
    return info.get("default_branch") or "main"


def upload_files(user: str, repo: str, token: str, branch: str) -> None:
    files = collect_files()
    print(f"Uploading {len(files)} files to {branch}...")
    for rel, path in files:
        content_b64 = base64.b64encode(path.read_bytes()).decode("ascii")
        api(
            "PUT",
            f"/repos/{user}/{repo}/contents/{rel}",
            token,
            {
                "message": f"Add {rel}",
                "content": content_b64,
                "branch": branch,
            },
        )
        print(f"  + {rel}")


def trigger_build(user: str, repo: str, token: str, branch: str) -> None:
    print("Triggering Build M4cNik IPA workflow...")
    api(
        "POST",
        f"/repos/{user}/{repo}/actions/workflows/build-ipa.yml/dispatches",
        token,
        {"ref": branch},
    )
    print(f"Workflow started. Open: https://github.com/{user}/{repo}/actions")


def main() -> None:
    p = argparse.ArgumentParser(description="Deploy m4cnik-app to GitHub")
    p.add_argument("--user", required=True, help="GitHub username or org")
    p.add_argument("--repo", default="m4cnik-app", help="Repository name")
    p.add_argument("--branch", default="main", help="Target branch")
    p.add_argument("--private", action="store_true", help="Create private repo")
    args = p.parse_args()

    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if not token:
        raise SystemExit(
            "Set GITHUB_TOKEN first (do not paste token in chat):\n"
            '  PowerShell: $env:GITHUB_TOKEN = "ghp_..."'
        )

    branch = ensure_repo(args.user, args.repo, token, args.private)
    if branch != args.branch:
        print(f"Note: default branch is {branch}, using it.")
        args.branch = branch
    upload_files(args.user, args.repo, token, args.branch)
    trigger_build(args.user, args.repo, token, args.branch)
    print("\nDone. In ~3-5 min download artifact M4cNikApp-ipa from Actions.")


if __name__ == "__main__":
    main()
