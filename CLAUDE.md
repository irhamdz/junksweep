# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## GitHub

- Always use the GitHub account `irhamdz` for all GitHub work in this repo (push, pull, `gh` commands, PRs, issues).
- Remote: `git@github.com:irhamdz/junksweep.git` (public). SSH for `github.com` already logs in as `irhamdz`.
- The `gh` CLI has two accounts, and the active account can be `irhamdzuhri`. Before a `gh` command, check with `gh auth status`. Run `gh auth switch -u irhamdz` if necessary, or set `GH_TOKEN=$(gh auth token -u irhamdz)` for one command.
- Commit author for this repo: `Irham Dzuhri <irhamdz@gmail.com>` (set in the local git config).

## Project

JunkSweep is an iOS app (SwiftUI, iOS 17+, Swift 5, Xcode 16+). It scans the photo library on the device for junk and deletes it in bulk. There is one app target (`JunkSweep`). There is no test target, no linter, and no package dependencies.

## Commands

```sh
# Build for the simulator
xcodebuild -project JunkSweep.xcodeproj -scheme JunkSweep \
  -destination 'generic/platform=iOS Simulator' build

# Open one screen at launch (DEBUG only), for screenshots
xcrun simctl launch booted com.example.JunkSweep -SweepStart review   # home|review|similar|videos|confirm|done
```

- The simulator has only a few sample photos. Test the scan on a real iPhone.
- On the simulator, `simctl privacy grant` does not give full photo access. The user must tap Allow.

## Architecture

- **`JunkScanner`** (`JunkSweep/JunkScanner.swift`): a synchronous scan that runs on a detached task. It sends `ScanProgress` reports (with a `ScanResult` snapshot) every `reportInterval` assets. All detection thresholds are properties here (blur, Vision similarity distance and time window, large or short video). README says the values are starting values to tune on real photos.
- **`LibraryStore`** (`JunkSweep/LibraryStore.swift`): the single `@MainActor @Observable` state, put in the environment by `JunkSweepApp`. It owns photo authorization, the scan task, progress, `result`, and `delete(_:)`. Keep these rules:
  - A first scan shows partial results. A rescan keeps the old results until it ends.
  - Reports that arrive late are dropped by `step`.
  - Items deleted during a scan go to `deletedIDs`, so later reports do not bring them back.
  - `delete` removes all items in one `performChanges` call, so iOS asks for one confirmation. A user cancel is not an error.
- **`Models.swift`**: `JunkCategory`, `JunkItem` (equality by `asset.localIdentifier`), and `ScanResult`. `ScanResult.suggested(for:)` gives the default deletions. For similar photos, it keeps the sharpest photo of each group.
- **Sweep UI** (`JunkSweep/Sweep/`): the current UI. `SweepRootView` owns the `NavigationStack` path (`SweepRoute`) and shows `ConfirmSheet` as an overlay, not as a system sheet. Screens navigate through the `\.sweep` environment value (`SweepNavigator.open` / `.confirm`), not through bindings. `CleanPlan` drops items that are already in an earlier group, so no item is deleted twice.
- **Old UI**: `HomeView.swift` and `CategoryView.swift` are an older plain-list UI. The app does not use them.

## Design

- `design/*.dc.html` are the UI source of truth (one screen per file, 390×844 pt). `HANDOFF.md` (a copy is in `design/`) lists the flow, the tokens, and the behavior to implement. In the designs, "Sweep" is a placeholder name. Show "JunkSweep" in the app.
- Put every color, type size, radius, and shadow in `JunkSweep/Sweep/Theme.swift` (`Palette`, `.textStyle(_:)`). Do not hard-code these values in views.
- The app forces light mode (`.preferredColorScheme(.light)`).

## Known limits (from README)

- File size uses the private `fileSize` key of `PHAssetResource`.
- For photos that are only in iCloud, the scan downloads a small copy for the blur and similar checks.
- With limited photo access, the scan sees only the shared photos.
