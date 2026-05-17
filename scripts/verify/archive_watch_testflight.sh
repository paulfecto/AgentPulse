#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

: "${DEVELOPER_DIR:=/Applications/Xcode.app/Contents/Developer}"
: "${AGENT_PULSE_DEVELOPMENT_TEAM:=H86Z687FT6}"
: "${AGENT_PULSE_TESTFLIGHT_BUILD_ROOT:=$ROOT_DIR/Build/TestFlight}"
: "${AGENT_PULSE_ARCHIVE_SCHEME:=AgentPulseMobile}"
: "${AGENT_PULSE_ARCHIVE_DESTINATION:=generic/platform=iOS}"
: "${AGENT_PULSE_UPLOAD_TESTFLIGHT:=0}"
: "${AGENT_PULSE_TESTFLIGHT_INTERNAL_ONLY:=1}"
: "${AGENT_PULSE_EXPORT_SIGNING_STYLE:=automatic}"
: "${AGENT_PULSE_ARCHIVE_CODE_SIGN_IDENTITY:=}"
: "${AGENT_PULSE_EXPORT_SIGNING_CERTIFICATE:=iPhone Distribution}"
: "${AGENT_PULSE_BUILD_NUMBER:=$(date +%Y%m%d%H%M)}"
if [[ -z "${AGENT_PULSE_EXPORT_METHOD:-}" ]]; then
  if [[ "$AGENT_PULSE_UPLOAD_TESTFLIGHT" == "1" ]]; then
    AGENT_PULSE_EXPORT_METHOD="app-store-connect"
  else
    AGENT_PULSE_EXPORT_METHOD="release-testing"
  fi
fi
export DEVELOPER_DIR
export AGENT_PULSE_DEVELOPMENT_TEAM
export AGENT_PULSE_TESTFLIGHT_INTERNAL_ONLY
export AGENT_PULSE_EXPORT_SIGNING_STYLE
export AGENT_PULSE_ARCHIVE_CODE_SIGN_IDENTITY
export AGENT_PULSE_EXPORT_SIGNING_CERTIFICATE
export AGENT_PULSE_EXPORT_METHOD
export AGENT_PULSE_BUILD_NUMBER

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is not installed; install full Xcode to archive Agent Pulse Watch." >&2
  exit 127
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "xcodebuild is unavailable because DEVELOPER_DIR is not a full Xcode install." >&2
  exit 127
fi

extra_auth=()
if [[ -n "${AGENT_PULSE_APPSTORE_CONNECT_API_KEY_PATH:-}" || -n "${AGENT_PULSE_APPSTORE_CONNECT_KEY_ID:-}" || -n "${AGENT_PULSE_APPSTORE_CONNECT_ISSUER_ID:-}" ]]; then
  if [[ -z "${AGENT_PULSE_APPSTORE_CONNECT_API_KEY_PATH:-}" || -z "${AGENT_PULSE_APPSTORE_CONNECT_KEY_ID:-}" || -z "${AGENT_PULSE_APPSTORE_CONNECT_ISSUER_ID:-}" ]]; then
    cat >&2 <<MSG
Set all three App Store Connect variables:
  AGENT_PULSE_APPSTORE_CONNECT_API_KEY_PATH=/secure/path/AuthKey_XXXX.p8
  AGENT_PULSE_APPSTORE_CONNECT_KEY_ID=XXXX
  AGENT_PULSE_APPSTORE_CONNECT_ISSUER_ID=YYYY
MSG
    exit 2
  fi
  extra_auth+=(
    -authenticationKeyPath "$AGENT_PULSE_APPSTORE_CONNECT_API_KEY_PATH"
    -authenticationKeyID "$AGENT_PULSE_APPSTORE_CONNECT_KEY_ID"
    -authenticationKeyIssuerID "$AGENT_PULSE_APPSTORE_CONNECT_ISSUER_ID"
  )
fi

if [[ "$AGENT_PULSE_UPLOAD_TESTFLIGHT" == "1" && "${#extra_auth[@]}" -eq 0 ]]; then
  cat >&2 <<MSG
BLOCKER: TestFlight upload requested but no App Store Connect API key was provided.
Set:
  AGENT_PULSE_APPSTORE_CONNECT_API_KEY_PATH=/secure/path/AuthKey_XXXX.p8
  AGENT_PULSE_APPSTORE_CONNECT_KEY_ID=XXXX
  AGENT_PULSE_APPSTORE_CONNECT_ISSUER_ID=YYYY
or run with AGENT_PULSE_UPLOAD_TESTFLIGHT=0 to create a local export only.
MSG
  exit 2
fi

if [[ "$AGENT_PULSE_EXPORT_SIGNING_STYLE" != "automatic" && "$AGENT_PULSE_EXPORT_SIGNING_STYLE" != "manual" ]]; then
  echo "AGENT_PULSE_EXPORT_SIGNING_STYLE must be either automatic or manual." >&2
  exit 2
fi

if [[ "$AGENT_PULSE_EXPORT_SIGNING_STYLE" == "manual" ]]; then
  if [[ -z "${AGENT_PULSE_EXPORT_IOS_PROFILE_NAME:-}" || -z "${AGENT_PULSE_EXPORT_WATCH_PROFILE_NAME:-}" ]]; then
    cat >&2 <<MSG
Manual export signing requires both profile names:
  AGENT_PULSE_EXPORT_IOS_PROFILE_NAME='Agent Pulse iOS App Store profile name'
  AGENT_PULSE_EXPORT_WATCH_PROFILE_NAME='Agent Pulse Watch App Store profile name'
MSG
    exit 2
  fi
  export AGENT_PULSE_EXPORT_IOS_PROFILE_NAME
  export AGENT_PULSE_EXPORT_WATCH_PROFILE_NAME
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE_PATH="$AGENT_PULSE_TESTFLIGHT_BUILD_ROOT/archives/AgentPulseWatch-$STAMP.xcarchive"
EXPORT_PATH="$AGENT_PULSE_TESTFLIGHT_BUILD_ROOT/export-$STAMP"
EXPORT_OPTIONS="$AGENT_PULSE_TESTFLIGHT_BUILD_ROOT/exportOptions-$STAMP.plist"
mkdir -p "$(dirname "$ARCHIVE_PATH")" "$EXPORT_PATH"

export AGENT_PULSE_EXPORT_OPTIONS="$EXPORT_OPTIONS"
export AGENT_PULSE_EXPORT_DESTINATION="$([[ "$AGENT_PULSE_UPLOAD_TESTFLIGHT" == "1" ]] && echo upload || echo export)"
python3 - <<'PY'
import os
import plistlib

options = {
    "destination": os.environ["AGENT_PULSE_EXPORT_DESTINATION"],
    "method": os.environ["AGENT_PULSE_EXPORT_METHOD"],
    "teamID": os.environ["AGENT_PULSE_DEVELOPMENT_TEAM"],
    "signingStyle": os.environ["AGENT_PULSE_EXPORT_SIGNING_STYLE"],
    "stripSwiftSymbols": True,
    "uploadSymbols": True,
    "manageAppVersionAndBuildNumber": True,
    "testFlightInternalTestingOnly": os.environ.get("AGENT_PULSE_TESTFLIGHT_INTERNAL_ONLY") == "1",
}

if options["signingStyle"] == "manual":
    options["signingCertificate"] = os.environ["AGENT_PULSE_EXPORT_SIGNING_CERTIFICATE"]
    options["provisioningProfiles"] = {
        "com.paulfecto.AgentPulse": os.environ["AGENT_PULSE_EXPORT_IOS_PROFILE_NAME"],
        "com.paulfecto.AgentPulse.watchkitapp": os.environ["AGENT_PULSE_EXPORT_WATCH_PROFILE_NAME"],
    }

with open(os.environ["AGENT_PULSE_EXPORT_OPTIONS"], "wb") as plist:
    plistlib.dump(options, plist, fmt=plistlib.FMT_XML, sort_keys=False)
PY

archive_args=(
  xcodebuild
  -project apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj
  -scheme "$AGENT_PULSE_ARCHIVE_SCHEME"
  -configuration Release
  -destination "$AGENT_PULSE_ARCHIVE_DESTINATION"
  -archivePath "$ARCHIVE_PATH"
  DEVELOPMENT_TEAM="$AGENT_PULSE_DEVELOPMENT_TEAM"
  CURRENT_PROJECT_VERSION="$AGENT_PULSE_BUILD_NUMBER"
  CODE_SIGN_STYLE=Automatic
  CODE_SIGNING_ALLOWED=YES
  CODE_SIGNING_REQUIRED=YES
  -allowProvisioningUpdates
)
if [[ -n "$AGENT_PULSE_ARCHIVE_CODE_SIGN_IDENTITY" ]]; then
  archive_args+=(CODE_SIGN_IDENTITY="$AGENT_PULSE_ARCHIVE_CODE_SIGN_IDENTITY")
fi
if [[ "${#extra_auth[@]}" -gt 0 ]]; then
  archive_args+=("${extra_auth[@]}")
fi
archive_args+=(archive)
"${archive_args[@]}"

export_args=(
  xcodebuild
  -exportArchive
  -archivePath "$ARCHIVE_PATH"
  -exportPath "$EXPORT_PATH"
  -exportOptionsPlist "$EXPORT_OPTIONS"
  -allowProvisioningUpdates
)
if [[ "${#extra_auth[@]}" -gt 0 ]]; then
  export_args+=("${extra_auth[@]}")
fi
"${export_args[@]}"

cat <<MSG
Agent Pulse Watch TestFlight archive flow completed.
Archive: $ARCHIVE_PATH
Export:  $EXPORT_PATH
Options: $EXPORT_OPTIONS
Upload:  $AGENT_PULSE_UPLOAD_TESTFLIGHT
MSG
