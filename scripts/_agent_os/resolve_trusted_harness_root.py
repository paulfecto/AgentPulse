#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tomllib
from pathlib import Path
from urllib.parse import urlparse

try:
    from cryptography.exceptions import InvalidSignature
    from cryptography.hazmat.primitives import serialization
except ModuleNotFoundError as exc:
    raise RuntimeError(
        "agentOS requires the Python 'cryptography' package to verify the signed harness manifest"
    ) from exc


TRUSTED_MANIFEST_PUBLIC_KEY_SHA256 = "0fcea005dc6fc1487cf18da2c92266803498e0e0edaab551f3230caf49aee8ab"
TRUSTED_MANIFEST_PUBLIC_KEY_PEM = b"""-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAXGOEH5tzZD15Hdd8VipJS27J31RBLDeLb1Nh3VjQDJ8=
-----END PUBLIC KEY-----
"""


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def load_json_object(path: Path) -> dict[str, object]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        fail(f"Schema file is not a JSON object: {path}")
    return data


def normalize_github_repo_url(url: str) -> str:
    parsed = urlparse(url.strip())
    if parsed.scheme != "https" or parsed.netloc != "github.com":
        fail("repo_harness.toml global_harness_repo must be a valid https://github.com/<owner>/<repo> URL")
    parts = [part for part in parsed.path.split("/") if part]
    if len(parts) != 2:
        fail("repo_harness.toml global_harness_repo must be a valid https://github.com/<owner>/<repo> URL")
    owner, repo = parts
    if repo.endswith(".git"):
        repo = repo[:-4]
    return f"https://github.com/{owner}/{repo}"


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_git_head_commit(root: Path) -> str:
    result = subprocess.run(
        ["git", "-C", str(root), "rev-parse", "HEAD"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0 or not result.stdout.strip():
        fail(f"Unable to resolve git HEAD for the trusted agentOS checkout: {root}")
    return result.stdout.strip()


def load_trusted_public_key() -> object:
    actual_public_key_sha256 = hashlib.sha256(TRUSTED_MANIFEST_PUBLIC_KEY_PEM).hexdigest()
    if actual_public_key_sha256 != TRUSTED_MANIFEST_PUBLIC_KEY_SHA256:
        fail("Built-in agentOS public trust key does not match the expected fingerprint")
    return serialization.load_pem_public_key(TRUSTED_MANIFEST_PUBLIC_KEY_PEM)


def iter_manifest_items(manifest: dict[str, object]) -> list[dict[str, object]]:
    items: list[dict[str, object]] = []
    for value in manifest.values():
        if isinstance(value, list):
            items.extend(
                item
                for item in value
                if isinstance(item, dict)
                and str(item.get("path") or "").strip()
                and str(item.get("sha256") or "").strip()
            )
    return items


def verify_manifest_signature(resolved_harness_root: Path) -> None:
    manifest_path = resolved_harness_root / "manifest/harness_manifest.json"
    signature_path = resolved_harness_root / "manifest/harness_manifest.sig"
    if not manifest_path.exists():
        fail(f"Resolved global harness root is missing manifest/harness_manifest.json: {resolved_harness_root}")
    if not signature_path.exists():
        fail(f"Resolved global harness root is missing manifest/harness_manifest.sig: {resolved_harness_root}")
    public_key = load_trusted_public_key()
    try:
        public_key.verify(signature_path.read_bytes(), manifest_path.read_bytes())
    except InvalidSignature:
        fail("Resolved global harness manifest signature is invalid for the trusted agentOS public key")


def verify_resolved_harness_root(
    resolved_harness_root: Path,
    declared_repo_url: str,
    declared_ref: str,
    declared_manifest_sha256: str,
) -> None:
    manifest_path = resolved_harness_root / "manifest/harness_manifest.json"
    verify_manifest_signature(resolved_harness_root)
    actual_manifest_sha256 = sha256_file(manifest_path)
    if declared_manifest_sha256 and actual_manifest_sha256 != declared_manifest_sha256:
        fail(
            "Resolved global harness root manifest hash does not match repo_harness.toml "
            f"global_harness_manifest_sha256: {actual_manifest_sha256} != {declared_manifest_sha256}"
        )
    manifest = load_json_object(manifest_path)
    actual_repo = normalize_github_repo_url(str(manifest.get("harness_repo") or ""))
    if actual_repo != declared_repo_url:
        fail(
            "Resolved global harness root does not match repo_harness.toml global_harness_repo: "
            f"{actual_repo} != {declared_repo_url}"
        )
    manifest_ref = str(manifest.get("harness_ref") or "").strip()
    if not manifest_ref:
        fail("Resolved global harness manifest is missing harness_ref")
    actual_head = read_git_head_commit(resolved_harness_root)
    if actual_head != declared_ref:
        fail(
            "Resolved global harness checkout HEAD does not match repo_harness.toml global_harness_ref: "
            f"{actual_head} != {declared_ref}"
        )
    for item in iter_manifest_items(manifest):
        relative_path = str(item.get("path") or "").strip()
        expected_sha256 = str(item.get("sha256") or "").strip()
        if not relative_path or not expected_sha256:
            fail("Resolved global harness manifest contains an item without path/sha256")
        item_path = (resolved_harness_root / relative_path).resolve()
        try:
            item_path.relative_to(resolved_harness_root)
        except ValueError:
            fail(f"Resolved global harness manifest contains a path that escapes the harness root: {relative_path}")
        if not item_path.exists():
            fail(f"Resolved global harness manifest points to a missing file: {item_path}")
        if sha256_file(item_path) != expected_sha256:
            fail(f"Resolved global harness file hash does not match the manifest inventory: {item_path}")


def main() -> None:
    if len(sys.argv) != 2:
        fail("Usage: resolve_trusted_harness_root.py <repo_harness.toml>")
    repo_harness_path = Path(sys.argv[1]).resolve()
    if not repo_harness_path.exists():
        fail(f"Missing repo_harness.toml: {repo_harness_path}")
    with repo_harness_path.open("rb") as handle:
        data = tomllib.load(handle)
    repo_root = repo_harness_path.parent
    global_harness_root = str(data.get("global_harness_root") or "").strip()
    global_harness_ref = str(data.get("global_harness_ref") or "").strip()
    global_harness_manifest_sha256 = str(data.get("global_harness_manifest_sha256") or "").strip()
    if not global_harness_root or not global_harness_ref or not global_harness_manifest_sha256:
        fail("repo_harness.toml is missing global harness trust fields")
    declared_repo_url = normalize_github_repo_url(str(data.get("global_harness_repo") or ""))
    resolved_harness_root = (repo_root / global_harness_root).resolve()
    verify_resolved_harness_root(
        resolved_harness_root,
        declared_repo_url,
        global_harness_ref,
        global_harness_manifest_sha256,
    )
    print(resolved_harness_root)


if __name__ == "__main__":
    main()
