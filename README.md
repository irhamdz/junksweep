# JunkSweep

An iOS app (SwiftUI, iOS 17+) that finds junk in your photo library and deletes it in bulk.

## What it finds

| Category | How it detects |
| --- | --- |
| Screenshots | `PHAsset.mediaSubtypes` contains `.photoScreenshot` |
| Similar photos | Vision feature print distance ≤ 0.5, taken within 5 minutes of the previous photo |
| Blurry photos | Laplacian variance of a 512 px grayscale copy < 60 |
| Large videos | Size ≥ 100 MB |
| Short videos | Duration < 3 s |

All analysis runs on the device. Thresholds are in `JunkScanner.swift`. They are starting values. Tune them on real photos.

## Bulk clean

- Tap photos to select them. Long-press to preview.
- **Select All** selects the whole category.
- In **Similar Photos**, **Select Extras** and **Keep Best** select every photo except the sharpest one in each group.
- **Delete** removes all selected items in one change. iOS shows one confirmation for the whole batch.
- Deleted items go to **Recently Deleted** in the Photos app for 30 days.

## Run

1. Open `JunkSweep.xcodeproj` in Xcode 16 or later.
2. Select the JunkSweep target > Signing & Capabilities. Set your Team and a unique bundle ID.
3. Run on a real iPhone. The simulator has only a few sample photos.

## Known limits

- The scan checks photos one at a time. Large libraries can take several minutes.
- Photos that are only in iCloud: the scan downloads a small copy for the blur and similar checks. This uses network data. With no network, those photos are skipped for these checks.
- With limited photo access, the scan sees only the photos you shared. Home shows a card that opens Settings.
- File size uses the `fileSize` key of `PHAssetResource`. This key is not public API.
