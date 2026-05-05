# Agent Pulse Watch

Native SwiftUI watchOS v1 for Agent Pulse. The watch is a glance-and-act surface: it pairs with the Mac helper, shows high-attention threads, sends short replies, stops runs, opens Codex on the Mac, and registers an APNs token for minimal helper-driven notifications.

## Requirements

- Xcode 16 or newer with the watchOS SDK installed.
- Apple Developer Program team with push notification capability.
- Bundle id: `com.paulfecto.AgentPulse.watchkitapp`.
- APNs auth key (`.p8`), Team ID, Key ID, bundle id, and sandbox/production environment configured in Agent Pulse tablet settings.

## Xcode Setup

1. Create a new watchOS App target named `AgentPulseWatch`.
2. Set bundle id to `com.paulfecto.AgentPulse.watchkitapp`.
3. Add the Swift files in `AgentPulseWatch/` to the watch target.
4. Enable Push Notifications in Signing & Capabilities.
5. Use automatic signing or assign the matching provisioning profile.
6. Build for an Apple Watch simulator first, then a paired physical watch.

The source is intentionally checked in without a generated `.xcodeproj` so signing identities and team-specific provisioning stay local.

## Pairing

1. In Agent Pulse settings, generate a pairing PIN.
2. On the Watch app, enter the helper URL and the PIN.
3. The app calls `/pair/lookup/:pin`, pairs through `/device/pair`, stores the session in Keychain, requests notification permission, and registers its APNs token at `/devices/watch-push`.

Use the Cloudflare remote URL for pairing if the watch is not on the same local network as the helper.

## APNs Behavior

- Sandbox tokens only work with `environment = sandbox`.
- Production/TestFlight/App Store tokens require `environment = production`.
- Notification payloads include only `kind`, `threadId`, `serverName`, and a short `aps.alert`.
- Transcript text, raw provider payloads, and local file data are never sent in pushes.

## Manual Checks

- Build the watch target for a watchOS simulator in Xcode.
- Pair against a local helper using a fresh PIN.
- Confirm `/devices/watch-push` succeeds after notification permission.
- Trigger a finished, errored, and waiting-approval thread transition and confirm the notification opens the matching thread.
- Revoke the device in Agent Pulse settings and confirm protected requests show the revoked state.
