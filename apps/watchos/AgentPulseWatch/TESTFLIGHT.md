# Agent Pulse Watch TestFlight

This project can produce a TestFlight-ready iPhone container with the Agent
Pulse Watch app embedded. The iPhone app is intentionally minimal; its purpose
is to carry the Watch app through App Store Connect/TestFlight.

## Bundle and App Store Connect Setup

- iPhone container bundle ID: `com.paulfecto.AgentPulse`
- Watch app bundle ID: `com.paulfecto.AgentPulse.watchkitapp`
- Apple Developer team: `H86Z687FT6`
- Default App Store Connect name: `Agent Pulse Watch`
- Default SKU: `agent-pulse-watch`
- Primary language: English

Before upload, confirm both bundle identifiers exist in Apple Developer
Certificates, Identifiers & Profiles. Push Notifications must be enabled for
the Watch bundle. Create the App Store Connect app record for the iPhone
container bundle before the first upload.

## Archive Locally

Create a signed archive and local export without uploading:

```sh
AGENT_PULSE_UPLOAD_TESTFLIGHT=0 \
  bash scripts/verify/archive_watch_testflight.sh
```

The script writes archives, export folders, and generated export options under
`Build/TestFlight/`, which is intentionally ignored by git.

Archive-only runs default to Xcode's `release-testing` export method so local
verification does not upload. Upload mode uses `app-store-connect`.

## Upload to Internal TestFlight

Upload with an App Store Connect API key stored outside the repo:

```sh
AGENT_PULSE_APPSTORE_CONNECT_API_KEY_PATH=/secure/path/AuthKey_XXXX.p8 \
AGENT_PULSE_APPSTORE_CONNECT_KEY_ID=XXXX \
AGENT_PULSE_APPSTORE_CONNECT_ISSUER_ID=YYYY \
AGENT_PULSE_UPLOAD_TESTFLIGHT=1 \
  bash scripts/verify/archive_watch_testflight.sh
```

The script defaults to internal-only TestFlight by setting
`testFlightInternalTestingOnly = true`. Do not commit API keys, provisioning
profiles, certificates, or exported archives.

## Signing Notes

The Watch entitlement uses a build setting:

- Debug/local physical installs: `aps-environment = development`
- Release/TestFlight builds: `aps-environment = production`

The release archive uses automatic signing by default. If a local Xcode account
requires forcing a specific archive identity, set
`AGENT_PULSE_ARCHIVE_CODE_SIGN_IDENTITY`, but leave it unset for normal
TestFlight automation because export/upload signing is controlled by Xcode and
App Store Connect.

TestFlight installs register production APNs device tokens. Configure the
Agent Pulse helper Watch notification settings with `environment = production`
when testing pushes from a TestFlight build.

If automatic export signing fails because Xcode selects an older profile, rerun
with manual export signing:

```sh
AGENT_PULSE_EXPORT_SIGNING_STYLE=manual \
AGENT_PULSE_EXPORT_IOS_PROFILE_NAME='Agent Pulse iOS App Store profile name' \
AGENT_PULSE_EXPORT_WATCH_PROFILE_NAME='Agent Pulse Watch App Store profile name' \
AGENT_PULSE_APPSTORE_CONNECT_API_KEY_PATH=/secure/path/AuthKey_XXXX.p8 \
AGENT_PULSE_APPSTORE_CONNECT_KEY_ID=XXXX \
AGENT_PULSE_APPSTORE_CONNECT_ISSUER_ID=YYYY \
AGENT_PULSE_UPLOAD_TESTFLIGHT=1 \
  bash scripts/verify/archive_watch_testflight.sh
```

## Post-Upload Verification

After App Store Connect processes the build:

- Add the Apple ID as an internal tester if it is not already listed.
- Install Agent Pulse from TestFlight on the Apple Watch.
- Pair against `https://beta.dope-ai.kr/agent-pulse`.
- Confirm summary, thread detail, reply, stop, attention approval, start-thread,
  revoked, offline, and production APNs token-registration behavior.
