import os, requests
t = os.environ["GITHUB_TOKEN"]
h = {"Authorization": f"Bearer {t}", "Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"}
run_id = os.environ.get("RUN_ID", "28485140919")
jobs = requests.get(f"https://api.github.com/repos/Foxcoc/m4cnik-app/actions/runs/{run_id}/jobs", headers=h).json()
job = jobs["jobs"][0]
print("job", job["name"], job["conclusion"])
log = requests.get(
    f"https://api.github.com/repos/Foxcoc/m4cnik-app/actions/jobs/{job['id']}/logs",
    headers=h,
    allow_redirects=True,
)
for line in log.text.splitlines():
    if any(x in line for x in ["error:", "BUILD FAILED", "##[error]", "fatal error", "SwiftCompile"]):
        print(line.encode("ascii", "replace").decode())
