#!/usr/bin/env bash

set -euo pipefail

DEVELOPMENT_DOMAIN="${DEVELOPMENT_DOMAIN:-beta.dope-ai.kr}"
AGENT_PULSE_APP_BASE_PATH="${AGENT_PULSE_APP_BASE_PATH:-/agent-pulse}"
AGENT_PULSE_EDGE_PORT="${AGENT_PULSE_EDGE_PORT:-4355}"
AGENT_PULSE_EDGE_UPSTREAM_HOST="${AGENT_PULSE_EDGE_UPSTREAM_HOST:-http://127.0.0.1:${AGENT_PULSE_EDGE_PORT}}"
AGENT_PULSE_EDGE_UPSTREAM_CONTAINER="${AGENT_PULSE_EDGE_UPSTREAM_CONTAINER:-http://host.docker.internal:${AGENT_PULSE_EDGE_PORT}}"

log() {
  echo "[agent-pulse-edge-reconcile] $*"
}

detect_host_nginx_dev_conf() {
  if ! command -v nginx >/dev/null 2>&1; then
    return 1
  fi

  nginx -T 2>&1 | awk -v domain="$DEVELOPMENT_DOMAIN" '
    /^# configuration file / {
      file = $4
      sub(/:$/, "", file)
      next
    }
    $0 ~ ("server_name[[:space:]]+[^;]*" domain "([[:space:];]|$)") {
      print file
      exit
    }
  '
}

detect_container_nginx_dev_conf() {
  local container_name="$1"
  docker exec "$container_name" sh -lc '
    domain="${DEVELOPMENT_DOMAIN:-beta.dope-ai.kr}"
    nginx -T 2>&1 | awk -v domain="$domain" '"'"'
      /^# configuration file / {
        file = $4
        sub(/:$/, "", file)
      }
      $0 ~ ("server_name[[:space:]]+[^;]*" domain "([[:space:];]|$)") {
        print file
        exit
      }
    '"'"'
  '
}

detect_container_main_nginx_conf() {
  local container_name="$1"
  docker exec "$container_name" sh -lc '
    result="$(nginx -T 2>&1 | awk '"'"'
      /^# configuration file / {
        file = $4
        sub(/:$/, "", file)
        if (!main_file) main_file = file
        next
      }
      file != main_file && /^[[:space:]]*server[[:space:]]*\{/ {
        print file
        found = 1
        exit
      }
      END {
        if (!found && main_file) print main_file
      }
    '"'"')"
    if [ -n "$result" ]; then
      printf "%s\n" "$result"
      exit 0
    fi
    for candidate in /etc/nginx/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf /opt/bitnami/nginx/conf/nginx.conf; do
      if [ -f "$candidate" ]; then
        printf "%s\n" "$candidate"
        exit 0
      fi
    done
  '
}

detect_active_edge_container() {
  python3 - <<'PY'
import json
import subprocess
import sys


def sh(*args: str) -> str:
    return subprocess.run(args, capture_output=True, text=True, check=True).stdout


try:
    ids = [line.strip() for line in sh("docker", "ps", "-q").splitlines() if line.strip()]
except Exception:
    raise SystemExit(1)

candidates: list[tuple[int, int, str, str]] = []

for cid in ids:
    try:
        info = json.loads(sh("docker", "inspect", cid))[0]
    except Exception:
        continue
    ports = info.get("NetworkSettings", {}).get("Ports") or {}
    host_bindings = []
    for container_port in ("80/tcp", "443/tcp"):
        for binding in ports.get(container_port) or []:
            if binding.get("HostPort") in {"80", "443"}:
                host_bindings.append(binding.get("HostPort"))
    if not host_bindings:
        continue
    name = (info.get("Name") or "").lstrip("/")
    image = info.get("Config", {}).get("Image") or ""
    lowered = f"{name} {image}".lower()
    static_score = 0
    for token, weight in (("nginx", 4), ("proxy", 3), ("traefik", 2), ("caddy", 2)):
        if token in lowered:
            static_score += weight

    runtime_score = 0
    try:
        nginx_dump = sh("docker", "exec", cid, "sh", "-lc", "nginx -T 2>&1")
    except Exception:
        nginx_dump = ""
    for marker, weight in (
        ("beta.dope-ai.kr", 100),
        ("project-manager.dope-ai.kr", 95),
        ("/project-manager", 85),
        ("/pm-mcp", 60),
        ("/api", 40),
        ("/pm-oauth-mcp", 20),
    ):
        if marker in nginx_dump:
            runtime_score += weight
    if "beta.dope-ai.kr" not in nginx_dump and "/project-manager" not in nginx_dump:
        continue
    candidates.append((runtime_score, static_score, cid, name))

if not candidates:
    raise SystemExit(1)

candidates.sort(reverse=True)
print(candidates[0][2])
PY
}

map_host_path_from_container() {
  local container_name="$1"
  local container_path="$2"
  docker inspect "$container_name" --format '{{json .Mounts}}' | python3 - "$container_path" <<'PY'
import json
import sys

raw = sys.stdin.read().strip()
if not raw:
    raise SystemExit(0)

try:
    mounts = json.loads(raw)
except json.JSONDecodeError:
    raise SystemExit(0)

container_path = sys.argv[1]
best = None
for mount in mounts:
    source = mount.get("Source")
    destination = mount.get("Destination")
    if not source or not destination:
        continue
    normalized = destination.rstrip("/")
    if container_path == destination or container_path.startswith(normalized + "/"):
        suffix = container_path[len(normalized):]
        candidate = source.rstrip("/") + suffix
        depth = len(normalized)
        if best is None or depth > best[0]:
            best = (depth, candidate)

if best:
    print(best[1])
PY
}

rewrite_agentpulse_routes_file() {
  local conf_path="$1"
  local upstream="$2"
  local backup_suffix="$3"

  python3 - "$conf_path" "$upstream" "$backup_suffix" "$DEVELOPMENT_DOMAIN" "$AGENT_PULSE_APP_BASE_PATH" <<'PY'
from pathlib import Path
import re
import shutil
import sys

path = Path(sys.argv[1])
upstream = sys.argv[2].rstrip("/") + "/"
backup_suffix = sys.argv[3]
domain = sys.argv[4]
base_path = sys.argv[5].rstrip("/") or "/agent-pulse"

text = path.read_text(encoding="utf-8")
begin = "# Agent Pulse beta app proxy BEGIN"
end = "# Agent Pulse beta app proxy END"
had_marked_block = begin in text or end in text
if had_marked_block:
    pattern = re.compile(r"\n?[ \t]*# Agent Pulse beta app proxy BEGIN\n.*?# Agent Pulse beta app proxy END\n?", re.S)
    text = pattern.sub("\n", text)

server_matches = list(re.finditer(r"(^|\n)(?P<indent>[ \t]*)server[ \t]*\{", text))
blocks = []
for match in server_matches:
    start = match.start() + (1 if match.group(1) else 0)
    open_brace = text.find("{", match.end() - 1)
    depth = 0
    end_index = None
    for index in range(open_brace, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                end_index = index
                break
    if end_index is None:
        continue
    body = text[start:end_index + 1]
    if re.search(r"server_name\s+[^;]*" + re.escape(domain) + r"([;\s]|$)", body):
        score = 10 if re.search(r"listen\s+[^;]*443", body) else 0
        blocks.append((score, start, end_index, match.group("indent")))

if not blocks:
    raise SystemExit(f"Could not locate nginx server block for {domain}.")

blocks.sort(reverse=True)
_, start, end_index, indent = blocks[0]
target_body = text[start:end_index + 1]
if not had_marked_block and re.search(r"location\s+(?:=|(?:\^~))?\s*/agent-pulse(?:/)?\s*\{", target_body):
    raise SystemExit("Refusing to overwrite an unmarked /agent-pulse nginx location in the target server block.")

inner = indent + "  "
block = f"""
{inner}{begin}
{inner}location = {base_path} {{
{inner}  return 308 {base_path}/;
{inner}}}

{inner}location ^~ {base_path}/ {{
{inner}  proxy_pass {upstream};
{inner}  proxy_http_version 1.1;
{inner}  proxy_set_header Host $host;
{inner}  proxy_set_header X-Real-IP $remote_addr;
{inner}  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
{inner}  proxy_set_header X-Forwarded-Host $host;
{inner}  proxy_set_header X-Forwarded-Proto $scheme;
{inner}  proxy_set_header Upgrade $http_upgrade;
{inner}  proxy_set_header Connection $http_connection;
{inner}  proxy_buffering off;
{inner}  proxy_request_buffering off;
{inner}  proxy_read_timeout 3600s;
{inner}  proxy_send_timeout 3600s;
{inner}}}
{inner}{end}
"""

new_text = text[:end_index] + block + "\n" + text[end_index:]
backup_path = path.with_name(path.name + f".bak.{backup_suffix}")
shutil.copy2(path, backup_path)
path.write_text(new_text, encoding="utf-8")
print(backup_path)
PY
}

restore_backup() {
  local backup_path="$1"
  local target_path="$2"
  if [[ -n "$backup_path" && -f "$backup_path" ]]; then
    cp "$backup_path" "$target_path"
  fi
}

reload_host_nginx() {
  local conf_path="$1"
  local backup_suffix backup_path
  backup_suffix="$(date +%Y%m%d%H%M%S)"
  backup_path="$(rewrite_agentpulse_routes_file "$conf_path" "$AGENT_PULSE_EDGE_UPSTREAM_HOST" "$backup_suffix")"
  if ! nginx -t; then
    restore_backup "$backup_path" "$conf_path"
    nginx -t || true
    echo "Host nginx validation failed; restored previous config." >&2
    return 1
  fi
  nginx -s reload
}

reload_container_nginx_from_host_mount() {
  local container_name="$1"
  local conf_path="$2"
  local host_conf_path="$3"
  local backup_suffix backup_path
  backup_suffix="$(date +%Y%m%d%H%M%S)"
  backup_path="$(rewrite_agentpulse_routes_file "$host_conf_path" "$AGENT_PULSE_EDGE_UPSTREAM_CONTAINER" "$backup_suffix")"
  if ! docker exec "$container_name" nginx -t; then
    restore_backup "$backup_path" "$host_conf_path"
    docker exec "$container_name" nginx -t || true
    echo "Shared edge container validation failed; restored previous host-mounted config." >&2
    return 1
  fi
  docker exec "$container_name" nginx -s reload
}

reload_container_nginx_in_place() {
  local container_name="$1"
  local conf_path="$2"
  local tmp_conf backup_conf backup_suffix
  backup_suffix="$(date +%Y%m%d%H%M%S)"
  tmp_conf="$(mktemp -t agentpulse-edge-conf.XXXXXX)"
  backup_conf="${tmp_conf}.original"
  docker cp "${container_name}:${conf_path}" "$tmp_conf"
  cp "$tmp_conf" "$backup_conf"
  rewrite_agentpulse_routes_file "$tmp_conf" "$AGENT_PULSE_EDGE_UPSTREAM_CONTAINER" "$backup_suffix" >/dev/null
  docker cp "$tmp_conf" "${container_name}:${conf_path}"
  if ! docker exec "$container_name" nginx -t; then
    docker cp "$backup_conf" "${container_name}:${conf_path}" || true
    docker exec "$container_name" nginx -t || true
    rm -f "$tmp_conf" "$backup_conf" "${tmp_conf}.bak.${backup_suffix}"
    echo "Shared edge container validation failed; restored previous in-container config." >&2
    return 1
  fi
  docker exec "$container_name" nginx -s reload
  rm -f "$tmp_conf" "$backup_conf" "${tmp_conf}.bak.${backup_suffix}"
}

main() {
  local conf_path container_name host_conf_path

  if command -v nginx >/dev/null 2>&1; then
    conf_path="$(detect_host_nginx_dev_conf || true)"
    if [[ -n "$conf_path" && -f "$conf_path" && -w "$conf_path" ]]; then
      log "Updating host nginx config: $conf_path"
      reload_host_nginx "$conf_path"
      return 0
    fi
  fi

  log "Using active shared edge container for $DEVELOPMENT_DOMAIN"
  container_name="$(detect_active_edge_container || true)"
  if [[ -z "$container_name" ]]; then
    echo "Could not detect active shared edge container for $DEVELOPMENT_DOMAIN." >&2
    return 1
  fi
  if ! docker exec "$container_name" sh -lc 'command -v nginx >/dev/null 2>&1'; then
    echo "Active shared edge container does not expose nginx: $container_name" >&2
    return 1
  fi

  conf_path="$(detect_container_nginx_dev_conf "$container_name" || true)"
  if [[ -z "$conf_path" ]]; then
    conf_path="$(detect_container_main_nginx_conf "$container_name" || true)"
  fi
  if [[ -z "$conf_path" ]]; then
    echo "Could not locate shared edge nginx config in $container_name." >&2
    return 1
  fi

  host_conf_path="$(map_host_path_from_container "$container_name" "$conf_path" || true)"
  if [[ -n "$host_conf_path" && -f "$host_conf_path" && -w "$host_conf_path" ]]; then
    log "Updating host-mounted shared edge config: $host_conf_path ($container_name:$conf_path)"
    reload_container_nginx_from_host_mount "$container_name" "$conf_path" "$host_conf_path"
  else
    log "Updating in-container shared edge config: $container_name:$conf_path"
    reload_container_nginx_in_place "$container_name" "$conf_path"
  fi
}

main "$@"
