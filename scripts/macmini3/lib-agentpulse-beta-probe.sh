#!/usr/bin/env bash

AGENT_PULSE_PROBE_STATUS=""
AGENT_PULSE_PROBE_BODY=""
AGENT_PULSE_PROBE_ERROR=""

agentpulse_probe_url() {
  local url="$1"
  local output status body

  AGENT_PULSE_PROBE_STATUS=""
  AGENT_PULSE_PROBE_BODY=""
  AGENT_PULSE_PROBE_ERROR=""

  if ! output="$(curl --connect-timeout 5 --max-time 20 -sS -w $'\n%{http_code}' "$url" 2>&1)"; then
    AGENT_PULSE_PROBE_ERROR="curl failed for $url: $output"
    return 1
  fi

  status="${output##*$'\n'}"
  body="${output%$'\n'$status}"
  AGENT_PULSE_PROBE_STATUS="$status"
  AGENT_PULSE_PROBE_BODY="$body"
}

agentpulse_probe_preview() {
  printf '%s' "$AGENT_PULSE_PROBE_BODY" | sed -n '1,20p'
}

agentpulse_probe_body_is_html() {
  printf '%s' "$AGENT_PULSE_PROBE_BODY" |
    grep -Eiq '<!doctype html|<html|/project-manager/|<title>Dope-AI</title>'
}

agentpulse_probe_body_is_json() {
  printf '%s' "$AGENT_PULSE_PROBE_BODY" | python3 -c 'import json, sys; json.load(sys.stdin)' >/dev/null 2>&1
}

agentpulse_check_health_url() {
  local url="$1"
  local quiet="${2:-0}"

  if ! agentpulse_probe_url "$url"; then
    [[ "$quiet" == "1" ]] || printf '%s\n' "$AGENT_PULSE_PROBE_ERROR" >&2
    return 1
  fi

  if [[ "$AGENT_PULSE_PROBE_STATUS" != "200" ]]; then
    AGENT_PULSE_PROBE_ERROR="Expected HTTP 200 from $url, got $AGENT_PULSE_PROBE_STATUS"
    [[ "$quiet" == "1" ]] || printf '%s\n' "$AGENT_PULSE_PROBE_ERROR" >&2
    return 1
  fi

  if agentpulse_probe_body_is_html; then
    AGENT_PULSE_PROBE_ERROR="Expected Agent Pulse JSON from $url, got HTML/Project Manager shell"
    [[ "$quiet" == "1" ]] || printf '%s\n' "$AGENT_PULSE_PROBE_ERROR" >&2
    return 1
  fi

  if ! printf '%s' "$AGENT_PULSE_PROBE_BODY" | python3 -c '
import json
import sys

try:
    payload = json.load(sys.stdin)
except Exception:
    raise SystemExit(1)
if not isinstance(payload, dict):
    raise SystemExit(1)
if payload.get("codexAppServer") != "connected":
    raise SystemExit(2)
' >/dev/null 2>&1; then
    AGENT_PULSE_PROBE_ERROR="Expected Agent Pulse health JSON with codexAppServer connected from $url"
    [[ "$quiet" == "1" ]] || printf '%s\n' "$AGENT_PULSE_PROBE_ERROR" >&2
    return 1
  fi
}

agentpulse_require_health_url() {
  local url="$1"
  if ! agentpulse_check_health_url "$url"; then
    agentpulse_probe_preview >&2
    return 1
  fi
}

agentpulse_check_json_url() {
  local url="$1"
  local allowed_status_regex="$2"
  local quiet="${3:-0}"

  if ! agentpulse_probe_url "$url"; then
    [[ "$quiet" == "1" ]] || printf '%s\n' "$AGENT_PULSE_PROBE_ERROR" >&2
    return 1
  fi

  if ! [[ "$AGENT_PULSE_PROBE_STATUS" =~ ^($allowed_status_regex)$ ]]; then
    AGENT_PULSE_PROBE_ERROR="Expected HTTP $allowed_status_regex from $url, got $AGENT_PULSE_PROBE_STATUS"
    [[ "$quiet" == "1" ]] || printf '%s\n' "$AGENT_PULSE_PROBE_ERROR" >&2
    return 1
  fi

  if agentpulse_probe_body_is_html; then
    AGENT_PULSE_PROBE_ERROR="Expected JSON from $url, got HTML/Project Manager shell"
    [[ "$quiet" == "1" ]] || printf '%s\n' "$AGENT_PULSE_PROBE_ERROR" >&2
    return 1
  fi

  if ! agentpulse_probe_body_is_json; then
    AGENT_PULSE_PROBE_ERROR="Expected JSON from $url"
    [[ "$quiet" == "1" ]] || printf '%s\n' "$AGENT_PULSE_PROBE_ERROR" >&2
    return 1
  fi
}

agentpulse_require_json_url() {
  local url="$1"
  local allowed_status_regex="$2"
  if ! agentpulse_check_json_url "$url" "$allowed_status_regex"; then
    agentpulse_probe_preview >&2
    return 1
  fi
}

agentpulse_check_tablet_shell() {
  local url="$1"
  local quiet="${2:-0}"

  if ! agentpulse_probe_url "$url"; then
    [[ "$quiet" == "1" ]] || printf '%s\n' "$AGENT_PULSE_PROBE_ERROR" >&2
    return 1
  fi

  if [[ "$AGENT_PULSE_PROBE_STATUS" != "200" ]]; then
    AGENT_PULSE_PROBE_ERROR="Expected HTTP 200 from tablet shell $url, got $AGENT_PULSE_PROBE_STATUS"
    [[ "$quiet" == "1" ]] || printf '%s\n' "$AGENT_PULSE_PROBE_ERROR" >&2
    return 1
  fi

  if printf '%s' "$AGENT_PULSE_PROBE_BODY" | grep -Eiq '/project-manager/|<title>Dope-AI</title>'; then
    AGENT_PULSE_PROBE_ERROR="Expected Agent Pulse tablet shell from $url, got Project Manager shell"
    [[ "$quiet" == "1" ]] || printf '%s\n' "$AGENT_PULSE_PROBE_ERROR" >&2
    return 1
  fi

  if ! printf '%s' "$AGENT_PULSE_PROBE_BODY" | grep -Eq '<title>Agent Pulse</title>|Agent Pulse'; then
    AGENT_PULSE_PROBE_ERROR="Expected Agent Pulse tablet shell from $url"
    [[ "$quiet" == "1" ]] || printf '%s\n' "$AGENT_PULSE_PROBE_ERROR" >&2
    return 1
  fi
}

agentpulse_require_tablet_shell() {
  local url="$1"
  if ! agentpulse_check_tablet_shell "$url"; then
    agentpulse_probe_preview >&2
    return 1
  fi
}
