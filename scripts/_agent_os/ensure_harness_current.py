#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import os
import subprocess
import sys
import tomllib
from pathlib import Path
from typing import Any


DEFAULT_FETCH_TIMEOUT_SECONDS = 2.0


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def run(
    args: list[str],
    *,
    check: bool = False,
    capture: bool = True,
    timeout: float | None = None,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        text=True,
        capture_output=capture,
        check=check,
        timeout=timeout,
    )


def git(root: Path, *args: str, check: bool = False, timeout: float | None = None) -> subprocess.CompletedProcess[str]:
    return run(["git", "-C", str(root), *args], check=check, timeout=timeout)


def load_repo_harness(repo_harness_path: Path) -> dict[str, Any]:
    if not repo_harness_path.exists():
        fail(f"Missing repo_harness.toml: {repo_harness_path}")
    try:
        with repo_harness_path.open("rb") as handle:
            data = tomllib.load(handle)
    except (OSError, tomllib.TOMLDecodeError) as exc:
        fail(f"Could not parse repo_harness.toml: {exc}")
    if not isinstance(data, dict):
        fail("repo_harness.toml must decode to a TOML table")
    return data


def resolve_harness_root(repo_root: Path, data: dict[str, Any]) -> Path:
    configured = str(data.get("global_harness_root") or "").strip()
    if not configured:
        fail("repo_harness.toml is missing global_harness_root")
    path = Path(configured)
    if not path.is_absolute():
        path = repo_root / path
    resolved = path.resolve()
    if not resolved.exists():
        fail(f"Configured agentOS global_harness_root does not exist: {resolved}")
    return resolved


def is_git_checkout(path: Path) -> bool:
    result = git(path, "rev-parse", "--is-inside-work-tree")
    return result.returncode == 0 and result.stdout.strip() == "true"


def git_head(path: Path) -> str:
    result = git(path, "rev-parse", "HEAD")
    if result.returncode != 0 or not result.stdout.strip():
        fail(f"Unable to resolve git HEAD for {path}")
    return result.stdout.strip()


def git_show_text(path: Path, refspec: str) -> str | None:
    result = git(path, "show", refspec)
    if result.returncode != 0:
        return None
    return result.stdout


def use_worktree_harness_files(root: Path) -> bool:
    if os.environ.get("AGENT_OS_ALLOW_DIRTY_HARNESS") != "1" or not is_git_checkout(root):
        return False
    status = git(root, "status", "--porcelain", "--untracked-files=normal")
    return status.returncode == 0 and bool(status.stdout.strip())


def harness_file_text(root: Path, relative_path: str) -> str:
    if is_git_checkout(root) and not use_worktree_harness_files(root):
        from_head = git_show_text(root, f"HEAD:{relative_path}")
        if from_head is not None:
            return from_head
    path = root / relative_path
    if not path.exists():
        fail(f"agentOS checkout is missing {relative_path}: {root}")
    return path.read_text(encoding="utf-8")


def harness_file_bytes(root: Path, relative_path: str) -> bytes:
    if is_git_checkout(root) and not use_worktree_harness_files(root):
        from_head = git_show_text(root, f"HEAD:{relative_path}")
        if from_head is not None:
            return from_head.encode("utf-8")
    path = root / relative_path
    if not path.exists():
        fail(f"agentOS checkout is missing {relative_path}: {root}")
    return path.read_bytes()


def current_harness_status(root: Path) -> dict[str, str]:
    return {
        "harness_version": harness_file_text(root, "HARNESS_VERSION").strip(),
        "global_harness_ref": git_head(root) if is_git_checkout(root) else f"v{harness_file_text(root, 'HARNESS_VERSION').strip()}",
        "global_harness_manifest_sha256": hashlib.sha256(
            harness_file_bytes(root, "manifest/harness_manifest.json")
        ).hexdigest(),
    }


def declared_harness_status(data: dict[str, Any]) -> dict[str, str]:
    return {
        "harness_version": str(data.get("harness_version") or "").strip(),
        "global_harness_ref": str(data.get("global_harness_ref") or "").strip(),
        "global_harness_manifest_sha256": str(data.get("global_harness_manifest_sha256") or "").strip(),
    }


def update_available(declared: dict[str, str], current: dict[str, str]) -> bool:
    return any(declared.get(key) != current.get(key) for key in current)


def require_clean_harness_root(root: Path) -> None:
    if not is_git_checkout(root):
        return
    status = git(root, "status", "--porcelain", "--untracked-files=normal")
    if status.returncode != 0:
        fail(f"Unable to inspect agentOS checkout cleanliness: {root}")
    if status.stdout.strip() and os.environ.get("AGENT_OS_ALLOW_DIRTY_HARNESS") != "1":
        fail(
            "Refusing mandatory AgentOS pre-action update check because the configured "
            f"agentOS checkout is dirty: {root}\n"
            "Commit or stash the agentOS changes first, or set AGENT_OS_ALLOW_DIRTY_HARNESS=1 "
            "only for an intentional local test."
        )


def fetch_origin_main(root: Path) -> None:
    if not is_git_checkout(root):
        return
    remote = git(root, "remote", "get-url", "origin")
    if remote.returncode != 0 or not remote.stdout.strip():
        return
    timeout_raw = os.environ.get("AGENT_OS_PRE_ACTION_FETCH_TIMEOUT_SECONDS", "").strip()
    try:
        timeout = float(timeout_raw) if timeout_raw else DEFAULT_FETCH_TIMEOUT_SECONDS
    except ValueError:
        timeout = DEFAULT_FETCH_TIMEOUT_SECONDS
    if timeout <= 0:
        return
    try:
        result = git(root, "fetch", "--quiet", "origin", "main", timeout=timeout)
    except subprocess.TimeoutExpired:
        print(
            f"[agentOS] warning: timed out while checking origin/main for {root}; using local agentOS checkout",
            file=sys.stderr,
        )
        return
    if result.returncode != 0:
        print(
            f"[agentOS] warning: could not fetch origin/main for {root}; using local agentOS checkout",
            file=sys.stderr,
        )


def git_root_state(repo: Path) -> str:
    if not repo.exists():
        return "missing-path"
    result = git(repo, "rev-parse", "--show-toplevel")
    if result.returncode != 0 or not result.stdout.strip():
        return "non-git-root"
    top = Path(result.stdout.strip()).resolve()
    return "git-root" if top == repo.resolve() else "nested-git-root"


def current_branch(repo: Path) -> str:
    result = git(repo, "symbolic-ref", "--quiet", "--short", "HEAD")
    if result.returncode != 0 or not result.stdout.strip():
        return ""
    return result.stdout.strip()


def repo_is_clean(repo: Path) -> bool:
    status = git(repo, "status", "--porcelain", "--untracked-files=normal")
    if status.returncode != 0:
        fail(f"Unable to inspect repo cleanliness: {repo}")
    return not status.stdout.strip()


def require_auto_update_ready(repo: Path, harness_root: Path) -> None:
    state = git_root_state(repo)
    if state != "git-root":
        fail(f"AgentOS is stale, but this path is not an updateable git-root checkout: {state} ({repo})")
    if not current_branch(repo):
        fail(f"AgentOS is stale, but the repo is in detached HEAD and cannot be auto-updated safely: {repo}")
    if not repo_is_clean(repo):
        command = f"bash {harness_root / 'scripts/harness/update.sh'} --repo {repo} --accept-adoption-plan"
        fail(
            "AgentOS is stale, but the repo worktree is dirty. The mandatory pre-action gate "
            "will not destructively clean product work.\n"
            f"After preserving or committing your work, run: {command}"
        )


def update_repo(repo: Path, harness_root: Path) -> None:
    update_script = harness_root / "scripts/harness/update.sh"
    if not update_script.exists():
        fail(f"Configured agentOS checkout is missing update.sh: {update_script}")
    command = ["bash", str(update_script), "--repo", str(repo), "--accept-adoption-plan"]
    print("[agentOS] stale harness pin detected; updating repo before continuing...", file=sys.stderr)
    result = run(command, capture=False)
    if result.returncode != 0:
        fail(f"AgentOS automatic pre-action update failed with exit code {result.returncode}: {' '.join(command)}")


def ensure_current(repo_harness_path: Path) -> None:
    repo_harness_path = repo_harness_path.resolve()
    repo = repo_harness_path.parent
    data = load_repo_harness(repo_harness_path)
    harness_root = resolve_harness_root(repo, data)
    fetch_origin_main(harness_root)
    require_clean_harness_root(harness_root)
    declared = declared_harness_status(data)
    current = current_harness_status(harness_root)
    if not update_available(declared, current):
        return
    require_auto_update_ready(repo, harness_root)
    update_repo(repo, harness_root)
    refreshed_data = load_repo_harness(repo_harness_path)
    refreshed_declared = declared_harness_status(refreshed_data)
    refreshed_current = current_harness_status(harness_root)
    if update_available(refreshed_declared, refreshed_current):
        fail("AgentOS automatic pre-action update completed, but repo_harness.toml is still stale")
    print("[agentOS] pre-action AgentOS update completed; continuing.", file=sys.stderr)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("repo_harness", nargs="?", help="Path to repo_harness.toml")
    parser.add_argument("--repo", help="Repo root containing repo_harness.toml")
    args = parser.parse_args()
    if bool(args.repo_harness) == bool(args.repo):
        fail("Usage: ensure_harness_current.py <repo_harness.toml> OR ensure_harness_current.py --repo <repo-root>")
    repo_harness_path = Path(args.repo_harness) if args.repo_harness else Path(args.repo) / "repo_harness.toml"
    ensure_current(repo_harness_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
