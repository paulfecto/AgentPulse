# Execution plan

Add a TestFlight archive/upload workflow for the Agent Pulse Watch app. The
standalone watchOS archive proved useful for local validation but Xcode's
TestFlight export path requires an iPhone container, so the release package is
now an iPhone shell app embedding the Watch app.

- status: complete
- owner: codex
- started: 2026-05-16

## Target behavior

- AgentPulse can archive an iPhone container with the embedded watchOS app for
  App Store Connect/TestFlight using a repo-owned script.
- Upload requires explicit App Store Connect API-key environment variables.
- Release/TestFlight builds use production APNs entitlements; Debug builds keep
  development APNs entitlements.
- Secrets, provisioning profiles, and generated archives stay out of git.

## Planned write set

- `scripts/verify/archive_watch_testflight.sh`
- `apps/watchos/AgentPulseWatch/TESTFLIGHT.md`
- `apps/watchos/AgentPulseWatch/README.md`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch/AgentPulseWatch.entitlements`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch/Info.plist`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj/project.pbxproj`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj/xcshareddata/xcschemes/AgentPulseMobile.xcscheme`
- `apps/watchos/AgentPulseWatch/AgentPulseiOS/`
- `.gitignore`
- `package.json`

## Acceptance criteria

- Archive script mirrors the management-tool TestFlight pattern: generated
  export options, API-key upload auth, internal-only default, and automatic
  signing default.
- TestFlight docs identify required Apple Developer/App Store Connect setup and
  production APNs behavior.
- Docker product gates still pass.
- Watch Ultra simulator proof still passes.
- Release archive/export either succeeds or records an exact Apple-side blocker.

## Validation evidence

- `plutil -lint apps/watchos/AgentPulseWatch/AgentPulseWatch/Info.plist apps/watchos/AgentPulseWatch/AgentPulseWatch/AgentPulseWatch.entitlements` passed.
- `bash -n scripts/verify/archive_watch_testflight.sh` passed.
- Docker gate passed with `docker run --rm -v "$PWD":/work -v /work/node_modules -w /work node:22-bookworm bash -lc 'corepack enable && corepack prepare pnpm@10.28.2 --activate && pnpm install --frozen-lockfile && pnpm test && pnpm typecheck && pnpm build'`; result: 553 tests passed, typecheck passed, build passed.
- Watch Ultra simulator proof passed with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer bash scripts/verify/run_watch_ultra_simulator_preview.sh`.
- Upload secret guard passed: `AGENT_PULSE_UPLOAD_TESTFLIGHT=1 bash scripts/verify/archive_watch_testflight.sh` exits before archive with a missing App Store Connect API-key blocker.
- Archive/export proof passed for the original standalone watch app:
  `AGENT_PULSE_UPLOAD_TESTFLIGHT=0 bash scripts/verify/archive_watch_testflight.sh`
  produced `Build/TestFlight/archives/AgentPulseWatch-20260516-195257.xcarchive`
  and `Build/TestFlight/export-20260516-195257/AgentPulseWatch.ipa`.
- Local Xcode limitation recorded: the standalone watchOS archive rejects `method = app-store-connect` during local export with `expected one {release-testing, enterprise, debugging}`; archive-only mode therefore uses `release-testing`, while upload mode remains `app-store-connect`.
- iPhone-container simulator build passed:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj -scheme AgentPulseMobile -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build`.
- iPhone-container archive/export proof passed:
  `AGENT_PULSE_UPLOAD_TESTFLIGHT=0 bash scripts/verify/archive_watch_testflight.sh`
  produced `Build/TestFlight/archives/AgentPulseWatch-20260516-200602.xcarchive`
  and `Build/TestFlight/export-20260516-200602/AgentPulseMobile.ipa`.
- Upload attempt with the existing local App Store Connect API key archived the
  iPhone container and embedded Watch app successfully, then failed at App
  Store Connect app-record lookup. Xcode distribution log showed
  `filter[bundleId]=com.paulfecto.AgentPulse` returned `data: []` and
  `IDEDistribution.DistributionAppRecordProviderError.missingApp`.
- Direct App Store Connect API app-record creation was attempted with both
  locally available API keys. Both keys can authenticate and read App Store
  Connect, but `POST /v1/apps` is rejected by Apple with `403 FORBIDDEN_ERROR`
  and `The resource 'apps' does not allow 'CREATE'. Allowed operations are:
  GET_COLLECTION, GET_INSTANCE, UPDATE`.
- App Store Connect API readback confirmed Apple Developer identifiers already
  exist for `com.paulfecto.AgentPulse` and
  `com.paulfecto.AgentPulse.watchkitapp`; the Watch bundle has
  `PUSH_NOTIFICATIONS` enabled.
- Icon alpha check passed for every iPhone and Watch AppIcon PNG:
  `sips -g hasAlpha -g pixelWidth -g pixelHeight` reported `hasAlpha: no` for
  all app icon assets.
- Docker gate re-ran after the iPhone-container work and passed:
  `docker run --rm -v "$PWD":/work -v /work/node_modules -w /work node:22-bookworm bash -lc 'corepack enable && corepack prepare pnpm@10.28.2 --activate && pnpm install --frozen-lockfile && pnpm test && pnpm typecheck && pnpm build'`;
  result: 553 tests passed, typecheck passed, build passed.
- Watch Ultra simulator proof re-ran after the iPhone-container work and passed:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer bash scripts/verify/run_watch_ultra_simulator_preview.sh`.
- Current iPhone-container archive/export proof passed:
  `AGENT_PULSE_UPLOAD_TESTFLIGHT=0 bash scripts/verify/archive_watch_testflight.sh`
  produced `Build/TestFlight/archives/AgentPulseWatch-20260516-202213.xcarchive`
  and `Build/TestFlight/export-20260516-202213/AgentPulseMobile.ipa`.
- Static checks passed: `git diff --check`, `plutil -lint` for iOS Info.plist,
  Watch Info.plist, and Watch entitlements, `bash -n` for release/simulator
  scripts, and JSON parsing for watch/iOS asset catalogs.
- `git diff --check` passed.
- AgentOS `verify_harness.py` was attempted and failed before product validation due a pre-existing adapter drift: resolved global harness manifest hash `57b8c0603a99b59ba2fc6cbc37dee5c432662dfa75c1d0b412ba4915eb14ab5a` does not match `repo_harness.toml` expected `d1ea748c25f22a9243672f2791500d71971eb2c5eee8fb43f6f2a11502849a94`.
- AgentOS `verify_exec_plan.py --stage start` was attempted and failed on unrelated active plan liveness: `codex-mobile-watch-remote-control.md` heartbeat stale `9418s > 180s`.
- App Store Connect app record was created through the authenticated UI after
  API app creation was blocked. App id: `6770043269`; app name:
  `Agent Pulse Watch`; bundle id: `com.paulfecto.AgentPulse`.
- App Store profiles were created and installed locally for manual export:
  iOS profile `AgentPulse Mobile App Store 20260516-203452`
  (`5d97ea54-44f4-45ca-aef3-8cf6fe81b6be`) and Watch profile
  `AgentPulse Watch App Store 20260516-203452`
  (`5ba23494-a5a3-4043-a6c8-7529018f9bfe`).
- First signed upload reached App Store Connect package analysis and failed on
  missing required Watch icon slots:
  `29x29@2x`, `29x29@3x`, `50x50@2x`, and `108x108@2x`.
- Watch AppIcon catalog was patched to match App Store Connect's required
  companion settings, long look, and short look roles. Added
  `AppIcon-108@2x.png`; `sips` confirmed all four required icons have the
  expected pixel sizes and `hasAlpha: no`.
- TestFlight upload passed with
  `AGENT_PULSE_UPLOAD_TESTFLIGHT=1 bash scripts/verify/archive_watch_testflight.sh`;
  Xcode reported `Uploaded package is processing`, `Upload succeeded`,
  `Uploaded AgentPulseMobile`, and `** EXPORT SUCCEEDED **`.
  Archive:
  `Build/TestFlight/archives/AgentPulseWatch-20260516-203915.xcarchive`.
  Build number: `202605162039`.
- App Store Connect API readback confirmed build
  `f85ffd96-9cff-41bb-bd73-91e67b53b9ac`, version `202605162039`,
  `processingState = VALID`, `buildAudienceType = INTERNAL_ONLY`,
  and `usesNonExemptEncryption = false`.
- App Store Connect UI readback confirmed TestFlight > iOS Builds shows
  `0.1.0 (202605162039)`, `Internal`, `Ready to Test`, and
  `Expires in 90 days`.
- Internal TestFlight group `Agent Pulse Internal`
  (`c2cd43b5-2118-4bbb-99fe-83c9c86dd56c`) was created with
  `isInternalGroup = true` and `hasAccessToAllBuilds = true`.
- App Store Connect UI and API readback confirmed
  `Agent Pulse Internal` has `1 Tester` and `1 Build`; tester
  `paul.hong.ca@gmail.com` / `Paul Hong` is listed as internal and invited.

## Completion status

- state: complete
- result: Agent Pulse Watch is uploaded to App Store Connect/TestFlight as an
  internal-only build and assigned to the internal tester group for
  `paul.hong.ca@gmail.com`.
- harness-blocker: AgentOS verification is currently blocked by global harness hash drift and an unrelated stale active plan, not by the TestFlight release script changes.
