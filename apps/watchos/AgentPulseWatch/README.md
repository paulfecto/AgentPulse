# Agent Pulse Watch

Native SwiftUI watchOS v1 for Agent Pulse. The watch is a glance-and-act surface: it pairs with the Mac helper, shows high-attention threads, sends short replies, stops runs, opens Codex on the Mac, and can register an APNs token for minimal helper-driven notifications when push signing is enabled.

The Watch app icon and in-app mark are generated from the canonical Agent Pulse
logo at `apps/tablet/public/icon.svg`.

## Requirements

- Xcode 16 or newer with the watchOS SDK installed.
- Paid Apple Developer Program team with Push Notifications enabled for the
  Watch bundle ID.
- Personal Team signing can run a limited local build only after disabling the
  APNs entitlement and `AgentPulseRemoteNotificationsEnabled`.
- Bundle id: `com.paulfecto.AgentPulse.watchkitapp`.
- APNs auth key (`.p8`), Team ID, Key ID, bundle id, and sandbox/production environment configured in Agent Pulse tablet settings.
- A stable Cloudflare named tunnel hostname is required for Watch access away
  from the Mac's local network.

## Brand Assets

Regenerate the tracked Watch icons after changing `apps/tablet/public/icon.svg`:

```sh
pnpm watch:icons
```

The generated asset catalog lives at
`AgentPulseWatch/Assets.xcassets` and is wired to the `AppIcon` build setting in
`AgentPulseWatch.xcodeproj`.

## Xcode Setup

1. Open `AgentPulseWatch.xcodeproj`.
2. Keep bundle id `com.paulfecto.AgentPulse.watchkitapp`.
3. Keep Push Notifications enabled for the APNs-capable build.
4. Keep `aps-environment = development` in `AgentPulseWatch.entitlements` for
   sandbox installs.
5. Keep `AgentPulseRemoteNotificationsEnabled` set to `true` in `Info.plist`.
6. Use automatic signing with the paid team or assign the matching provisioning
   profile locally.
7. Build for an Apple Watch simulator first, then a paired physical watch.

Signing identities, Apple Team ID values, and provisioning profiles stay local. For command-line simulator checks use:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild \
  -project apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj \
  -scheme AgentPulseWatch \
  -destination 'generic/platform=watchOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Pairing

1. In Agent Pulse settings, generate a pairing PIN.
2. On the Watch app, enter the helper URL and the PIN.
3. The app calls `/pair/lookup/:pin`, pairs through `/device/pair`, stores the session in Keychain, and refreshes the watch summary. APNs token registration occurs only when `AgentPulseRemoteNotificationsEnabled` is true and the app is signed with the push entitlement.

Use the Cloudflare stable remote URL for pairing if the watch is not on the same local network as the helper. Do not pair the Watch against `127.0.0.1`.

For the Codex-safe world-accessible helper runtime, set the stable hostname and
start:

```sh
AGENT_PULSE_REMOTE_HOSTNAME=pulse.example.com pnpm watch:remote
```

This runtime uses isolated Agent Pulse settings/admin/keychain state and starts
the helper with `AGENT_PULSE_DISABLE_CODEX_DESKTOP=1`, so Open on Mac remains
disabled and Codex Desktop is not IPC-controlled. The helper still uses the real
macOS Codex app-server transport.

Optional APNs settings can be provided without storing secrets in git:

```sh
AGENT_PULSE_REMOTE_HOSTNAME=pulse.example.com \
AGENT_PULSE_APNS_TEAM_ID=H86Z687FT6 \
AGENT_PULSE_APNS_KEY_ID=<key id> \
AGENT_PULSE_APNS_KEY_PATH=/absolute/private/AuthKey_<key id>.p8 \
AGENT_PULSE_APNS_ENVIRONMENT=sandbox \
pnpm watch:remote
```

For local physical-device debugging, Debug builds can be bootstrapped through
`devicectl device process launch --environment-variables` with these keys:

- `AGENT_PULSE_BOOTSTRAP_BASE_URL`
- `AGENT_PULSE_BOOTSTRAP_DEVICE_ID`
- `AGENT_PULSE_BOOTSTRAP_TOKEN`
- `AGENT_PULSE_BOOTSTRAP_FINGERPRINT`

This is only compiled into Debug builds and is intended for assisted E2E setup
without storing signing or session secrets in git.

## APNs Behavior

- Sandbox tokens only work with `environment = sandbox`.
- Production/TestFlight/App Store tokens require `environment = production`.
- Notification payloads include only `kind`, `threadId`, `serverName`, and a short `aps.alert`.
- Transcript text, raw provider payloads, and local file data are never sent in pushes.

## Manual Checks

- Build the watch target for a watchOS simulator in Xcode.
- Pair against a local helper using a fresh PIN.
- Confirm `/devices/watch-push` succeeds after notification permission and the
  Watch app receives a sandbox APNs token.
- Trigger a finished, errored, and waiting-approval thread transition and confirm the notification opens the matching thread.
- Revoke the device in Agent Pulse settings and confirm protected requests show the revoked state.
