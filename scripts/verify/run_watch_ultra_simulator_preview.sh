#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

: "${DEVELOPER_DIR:=/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

PROJECT_DIR="$ROOT_DIR/apps/watchos/AgentPulseWatch"
ARTIFACT_DIR="$ROOT_DIR/docs/exec-plans/active/watch-ultra-simulator-preview-screenshots"
DERIVED_DATA="$ROOT_DIR/Build/XcodeDerivedData/watch-ultra-preview"
WATCH_BUNDLE_ID="com.paulfecto.AgentPulse.watchkitapp"

mkdir -p "$ARTIFACT_DIR"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is not installed; install full Xcode to run Watch preview." >&2
  exit 127
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "xcodebuild is unavailable because DEVELOPER_DIR is not a full Xcode install." >&2
  exit 127
fi

pick_watch_simulator() {
  python3 - <<'PY'
import json
import re
import subprocess

preview_name = "Agent Pulse Watch Ultra Preview"
preferred = [
    "Apple Watch Ultra 3 (49mm)",
    "Apple Watch Ultra 2 (49mm)",
    "Apple Watch Ultra (49mm)",
]

def version_key(identifier):
    match = re.search(r"(\d+)(?:-(\d+))?$", identifier)
    if not match:
        return (0, 0)
    return tuple(int(part or 0) for part in match.groups())

devices = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "-j", "devices", "available"]))
devicetypes = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "-j", "devicetypes"]))
runtimes = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "-j", "runtimes"]))

preview_matches = []
for runtime, entries in devices.get("devices", {}).items():
    if "watchOS" not in runtime:
        continue
    for entry in entries:
        if entry.get("isAvailable") and entry.get("name") == preview_name:
            preview_matches.append((version_key(runtime), entry["udid"]))
if preview_matches:
    preview_matches.sort(reverse=True)
    print(preview_matches[0][1])
    raise SystemExit(0)

runtime_candidates = [
    entry for entry in runtimes.get("runtimes", [])
    if entry.get("isAvailable") and "watchOS" in entry.get("identifier", "")
]
runtime_candidates.sort(key=lambda entry: version_key(entry["identifier"]), reverse=True)
if not runtime_candidates:
    raise SystemExit("Unable to find an available watchOS runtime")

for runtime in runtime_candidates:
    for name in preferred:
        device_type = next(
            (entry["identifier"] for entry in devicetypes.get("devicetypes", []) if entry.get("name") == name),
            None,
        )
        if device_type:
            udid = subprocess.check_output(
                [
                    "xcrun",
                    "simctl",
                    "create",
                    preview_name,
                    device_type,
                    runtime["identifier"],
                ],
                text=True,
            ).strip()
            print(udid)
            raise SystemExit(0)

raise SystemExit("Unable to find Apple Watch Ultra-family simulator device type")
PY
}

WATCH_UDID="$(pick_watch_simulator)"
echo "Using Watch simulator: $WATCH_UDID"

xcrun simctl shutdown "$WATCH_UDID" >/dev/null 2>&1 || true
if ! xcrun simctl erase "$WATCH_UDID" >/dev/null; then
  echo "Unable to reset dedicated Agent Pulse Watch Ultra preview simulator." >&2
  exit 1
fi
xcrun simctl boot "$WATCH_UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$WATCH_UDID" -b >/dev/null
xcrun simctl ui "$WATCH_UDID" appearance dark >/dev/null 2>&1 || true
xcrun simctl ui "$WATCH_UDID" content_size medium >/dev/null 2>&1 || true
open -a Simulator >/dev/null 2>&1 || true
python3 - "$WATCH_UDID" <<'PY'
import json
import subprocess
import sys

udid = sys.argv[1]
devices = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "-j", "devices", "available"]))
for runtime, entries in devices.get("devices", {}).items():
    for entry in entries:
        if entry.get("udid") == udid:
            runtime_name = runtime.rsplit(".", 1)[-1].replace("-", ".")
            print(f"Booted preview device: {entry.get('name')} ({runtime_name})")
            raise SystemExit(0)
PY

xcodebuild \
  -project "$PROJECT_DIR/AgentPulseWatch.xcodeproj" \
  -scheme AgentPulseWatch \
  -configuration Debug \
  -destination "platform=watchOS Simulator,id=$WATCH_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG \
  build >/dev/null

WATCH_APP="$DERIVED_DATA/Build/Products/Debug-watchsimulator/AgentPulseWatch.app"
test -d "$WATCH_APP"

xcrun simctl uninstall "$WATCH_UDID" "$WATCH_BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$WATCH_UDID" "$WATCH_APP"

capture_watch() {
  local state="$1"
  local filename="$2"
  local destination="$ARTIFACT_DIR/$filename"
  local temp_destination="/tmp/agentpulse-watch-preview-$filename"

  SIMCTL_CHILD_AGENT_PULSE_WATCH_PREVIEW_FIXTURE=1 \
    SIMCTL_CHILD_AGENT_PULSE_WATCH_PREVIEW_STATE="$state" \
    xcrun simctl launch --terminate-running-process "$WATCH_UDID" "$WATCH_BUNDLE_ID" >/dev/null
  sleep 3
  xcrun simctl io "$WATCH_UDID" screenshot --type=png "$temp_destination" >/dev/null
  cp "$temp_destination" "$destination"
}

capture_simulator_window() {
  local filename="$1"
  local destination="$ARTIFACT_DIR/$filename"
  local rect

  for _ in 1 2 3 4 5 6 7 8 9 10; do
    open -a Simulator >/dev/null 2>&1 || true
    sleep 1
    rect="$(osascript <<'APPLESCRIPT' 2>/dev/null || true
tell application "Simulator" to activate
delay 0.5
tell application "System Events"
  tell process "Simulator"
    repeat with candidateWindow in windows
      set windowName to name of candidateWindow
      if windowName contains "Agent Pulse Watch Ultra Preview" then
        set windowPosition to position of candidateWindow
        set windowSize to size of candidateWindow
        return ((item 1 of windowPosition) as text) & "," & ((item 2 of windowPosition) as text) & "," & ((item 1 of windowSize) as text) & "," & ((item 2 of windowSize) as text)
      end if
    end repeat
    repeat with candidateWindow in windows
      set windowName to name of candidateWindow
      if windowName contains "Ultra" or windowName contains "Watch" then
        set windowPosition to position of candidateWindow
        set windowSize to size of candidateWindow
        return ((item 1 of windowPosition) as text) & "," & ((item 2 of windowPosition) as text) & "," & ((item 1 of windowSize) as text) & "," & ((item 2 of windowSize) as text)
      end if
    end repeat
  end tell
end tell
APPLESCRIPT
)"
    if [[ -n "$rect" ]]; then
      break
    fi
  done

  if [[ -z "$rect" ]]; then
    echo "Unable to locate the Apple Watch Ultra Simulator window for rounded-body proof." >&2
    osascript <<'APPLESCRIPT' 2>/dev/null || true
tell application "System Events"
  tell process "Simulator"
    repeat with candidateWindow in windows
      log (name of candidateWindow as text)
    end repeat
  end tell
end tell
APPLESCRIPT
    return 1
  fi
  screencapture -x -R"$rect" "$destination"
}

SCENARIOS=(
  "pairing:pairing.png:pairing-simulator-window.png"
  "summary:summary.png:summary-simulator-window.png"
  "attention:attention.png:attention-simulator-window.png"
  "attentionDetail:attention-detail.png:attention-detail-simulator-window.png"
  "attentionActions:attention-detail-actions.png:attention-detail-actions-simulator-window.png"
  "start:start-thread.png:start-thread-simulator-window.png"
  "detail:thread-detail.png:thread-detail-simulator-window.png"
  "detailMessages:thread-detail-messages.png:thread-detail-messages-simulator-window.png"
  "detailActions:thread-detail-actions.png:thread-detail-actions-simulator-window.png"
  "empty:empty.png:empty-simulator-window.png"
  "offline:offline.png:offline-simulator-window.png"
  "error:error.png:error-simulator-window.png"
  "revoked:revoked.png:revoked-simulator-window.png"
)

for scenario in "${SCENARIOS[@]}"; do
  IFS=":" read -r state raw_name window_name <<<"$scenario"
  capture_watch "$state" "$raw_name"
  capture_simulator_window "$window_name"
done

python3 - "$ARTIFACT_DIR" <<'PY'
from pathlib import Path
import struct
import sys

artifact_dir = Path(sys.argv[1])
raw_names = [
    "pairing.png",
    "summary.png",
    "attention.png",
    "attention-detail.png",
    "attention-detail-actions.png",
    "start-thread.png",
    "thread-detail.png",
    "thread-detail-messages.png",
    "thread-detail-actions.png",
    "empty.png",
    "offline.png",
    "error.png",
    "revoked.png",
]
window_names = [
    "pairing-simulator-window.png",
    "summary-simulator-window.png",
    "attention-simulator-window.png",
    "attention-detail-simulator-window.png",
    "start-thread-simulator-window.png",
    "thread-detail-simulator-window.png",
    "thread-detail-messages-simulator-window.png",
    "thread-detail-actions-simulator-window.png",
    "attention-detail-actions-simulator-window.png",
    "empty-simulator-window.png",
    "offline-simulator-window.png",
    "error-simulator-window.png",
    "revoked-simulator-window.png",
]
expected_raw_sizes = {(410, 502), (422, 514)}

try:
    from PIL import Image
except Exception:
    Image = None

def png_size(path):
    with path.open("rb") as handle:
        header = handle.read(24)
    if not header.startswith(b"\x89PNG\r\n\x1a\n"):
        raise SystemExit(f"{path}: not a PNG")
    return struct.unpack(">II", header[16:24])

def content_ratio(path, threshold=24, stride=6):
    if Image is None:
        return None
    image = Image.open(path).convert("RGB")
    background = image.getpixel((0, 0))
    samples = 0
    content = 0
    for y in range(0, image.height, stride):
        for x in range(0, image.width, stride):
            samples += 1
            if sum(abs(image.getpixel((x, y))[index] - background[index]) for index in range(3)) > threshold:
                content += 1
    return content / max(samples, 1)

missing = [name for name in raw_names + window_names if not (artifact_dir / name).exists()]
if missing:
    raise SystemExit(f"Missing Watch preview captures: {', '.join(missing)}")

for name in raw_names:
    path = artifact_dir / name
    size = png_size(path)
    if size not in expected_raw_sizes:
        raise SystemExit(f"{path}: expected Apple Watch Ultra-family raw screenshot, got {size[0]}x{size[1]}")
    if path.stat().st_size < 5000:
        raise SystemExit(f"{path}: screenshot file is too small")
    ratio = content_ratio(path)
    if ratio is not None and ratio < 0.035:
        raise SystemExit(f"{path}: screenshot does not contain enough visible content ({ratio:.3f})")

for name in window_names:
    path = artifact_dir / name
    width, height = png_size(path)
    if width <= 410 or height <= 502:
        raise SystemExit(f"{path}: Simulator window/body proof is too small ({width}x{height})")
    if path.stat().st_size < 10000:
        raise SystemExit(f"{path}: Simulator window/body proof is too small on disk")
    ratio = content_ratio(path, threshold=18)
    if ratio is not None and ratio < 0.025:
        raise SystemExit(f"{path}: Simulator window/body proof does not contain enough visible content ({ratio:.3f})")

print("Validated scenario raw Watch screenshots plus actual Simulator window/body proofs")
PY

echo "Agent Pulse Watch Ultra simulator preview passed:"
printf '  %s\n' "$ARTIFACT_DIR"/*.png
