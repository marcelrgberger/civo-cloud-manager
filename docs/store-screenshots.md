# Store screenshots

The store screenshots of the Mac app are captured from the real app running on fictional demo data. Nothing leaves
the Mac and no Civo account is involved.

## Demo data mode

Launch argument `-CCMDemoData`, Debug builds only. Release builds do not contain the mode, the fixtures or the string.

- `DemoURLProtocol` answers every request of every session of the app locally. The Civo API is served from
  `DemoFixtures`; writes answer 405; unknown paths answer 404; any other host is blocked. Nothing is forwarded.
- State is chosen from the launch arguments on every access (`AppEnvironment`), so the order in which singletons and
  `@State` storage start does not matter. Defaults live in an ephemeral suite and files in a temporary directory,
  both removed when the app quits. The Keychain, the stored API key, the trial start, the closure queue and the
  charges cache of the installed app are never read or written.
- The IP lookup returns the documentation address `203.0.113.10`, and opening an active cluster does not connect to
  its Kubernetes API (no IP lookup, no firewall write, no kubeconfig request).
- The main window opens at launch, light, 1440 x 900 pt, on a 2x display that can hold it. The invisible
  accessibility element `demo.status` carries the counts of unserved requests.
- Fixtures use the documentation ranges 192.0.2.0/24, 198.51.100.0/24 and 203.0.113.0/24 and generic names.

## Tests

`CivoCloudManagerTests/DemoModeTests.swift` checks that the fixtures decode with the real models and contain what
each screen needs, the router rules, and the isolation of the startup path. The isolation suite only runs in a host
that was started in demo mode, because a host started the normal way has already read the real state. Run it with
the dedicated scheme:

    xcodebuild test -project CivoCloudManager.xcodeproj -scheme CivoCloudManagerDemoHost -destination 'platform=macOS' \
      -only-testing:CivoCloudManagerTests/DemoFixtureTests -only-testing:CivoCloudManagerTests/DemoRouterTests \
      -only-testing:CivoCloudManagerTests/DemoIsolationTests

Run it before any capture.

## Capturing

One-time per Mac: UI automation must be allowed, otherwise the test runner stops with "Timed out while enabling
automation mode": `sudo DevToolsSecurity -enable`.

    scripts/capture_store_screenshots.sh            # all 16 languages
    scripts/capture_store_screenshots.sh en de      # selected languages

The script builds once, runs the `CivoCloudManagerScreenshots` scheme per language and writes
`<root>/civocloudmanager-<version>/<lang>/NN-<screen>.png` plus `MANIFEST.md` (default root
`~/Developer/tmp/ccm-164-captures`, override with `CCM_CAPTURE_ROOT`). It waits for other builds, refuses to run
while the installed app is open and never touches the desktop with a pointer of its own: the UI test drives the app
through accessibility.

The screenshots are the whole window, light, exactly 2880 x 1800 px, without shadow. The test fails instead of
rescaling when the size differs. The language is checked against the string catalogue (three sidebar titles).

Screens: 01-dashboard, 02-firewall-change, 03-firewall-rules (Edit Rule sheet; the context menu closes when it is
used), 04-resize, 05-k8s-upgrade, 06-reserved-ips (Assign sheet over a free address), 07-tag-filter, 08-billing
(Cost Estimate).

To add a screen: add identifiers to the controls in `Utilities/AccessibilityID.swift`, then a test method that
navigates, waits for loaded content and calls `capture`.
