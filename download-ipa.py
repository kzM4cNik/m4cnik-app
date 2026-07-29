#!/usr/bin/env python3
"""Download latest M4cNikApp IPA artifact to Desktop/KASPI."""
import io
import json
import os
import sys
import urllib.request
import zipfile
from pathlib import Path

USER = "Foxcoc"
REPO = "m4cnik-app"
API = "https://api.github.com"
OUT_DIR = Path(__file__).resolve().parent.parent


def api(path):
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    req = urllib.request.Request(
        API + path,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "download-ipa",
        },
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.loads(resp.read().decode())


def download(url):
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "User-Agent": "download-ipa",
        },
    )
    opener = urllib.request.build_opener(RedirectWithoutAuth())
    with opener.open(req, timeout=300) as resp:
        return resp.read()


class RedirectWithoutAuth(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        new = urllib.request.Request(newurl, headers={"User-Agent": "download-ipa"})
        new.get_method = lambda: req.get_method()
        return new


def main():
    if not os.environ.get("GITHUB_TOKEN", "").strip():
        sys.exit("GITHUB_TOKEN not set")

    runs = api(f"/repos/{USER}/{REPO}/actions/runs?per_page=5&status=success")
    run = None
    art = None
    for candidate in runs["workflow_runs"]:
        arts = api(f"/repos/{USER}/{REPO}/actions/runs/{candidate['id']}/artifacts")
        art = next((a for a in arts["artifacts"] if a["name"] == "M4cNikApp-ipa"), None)
        if art:
            run = candidate
            break
    if not art or not run:
        sys.exit("Artifact M4cNikApp-ipa not found")

    print(f"Downloading artifact {art['id']} ({art['size_in_bytes']} bytes)...")
    blob = download(art["archive_download_url"])
    z = zipfile.ZipFile(io.BytesIO(blob))
    ipa_name = next(n for n in z.namelist() if n.endswith(".ipa"))
    ipa_bytes = z.read(ipa_name)
    out = OUT_DIR / "M4cNikApp-v1.3.ipa"
    out.write_bytes(ipa_bytes)
    print(f"SAVED {out}")
    print(f"SIZE {out.stat().st_size} bytes")


if __name__ == "__main__":
    main()
