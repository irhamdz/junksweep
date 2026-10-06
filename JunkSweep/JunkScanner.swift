import OSLog
import Photos
import UIKit
import Vision

private let log = Logger(subsystem: "JunkSweep", category: "scan")

/// Progress of a scan, with the junk found so far.
struct ScanProgress {
    enum Phase { case photos, videos, finished }

    /// Goes up with each report. Reports can arrive out of order, so use it to drop old ones.
    var step: Int
    var processed: Int
    var total: Int
    var phase: Phase
    var snapshot: ScanResult

    var fraction: Double { total == 0 ? 1 : Double(processed) / Double(total) }
}

/// Finds junk in the photo library. Runs synchronously, so call it off the main thread.
/// Stops early, with the results so far, when the current task is cancelled.
struct JunkScanner {
    /// Photos with a sharpness below this value count as blurry. Tune this on real photos.
    var blurThreshold: Double = 60
    /// Two photos count as similar when their feature-print distance is at or below this value. Tune this on real photos.
    var similarityThreshold: Float = 0.5
    /// Only photos taken this close in time can be similar.
    var similarityTimeWindow: TimeInterval = 5 * 60
    var largeVideoBytes: Int64 = 100 * 1_000_000
    var shortVideoSeconds: TimeInterval = 3
    /// Longest side, in pixels, of the copy used for analysis.
    var analysisSide: CGFloat = 512
    /// Send a progress report after this many items.
    var reportInterval = 100
    /// Download a small copy of photos that are only in iCloud, so they get the blur and similar checks too.
    /// This uses network data and makes the scan slower.
    var downloadsFromICloud = true

    func scan(progress: (ScanProgress) -> Void) -> ScanResult {
        var result = ScanResult()
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let photos = PHAsset.fetchAssets(with: .image, options: options)
        let videos = PHAsset.fetchAssets(with: .video, options: options)
        let total = photos.count + videos.count
        log.info("Scan started. Access: \(PHPhotoLibrary.authorizationStatus(for: .readWrite).rawValue, privacy: .public) (3 = full, 4 = limited). Photos: \(photos.count, privacy: .public). Videos: \(videos.count, privacy: .public).")
        Self.logLibraryBreakdown()
        var done = 0
        var reports = 0
        var phase = ScanProgress.Phase.photos

        func report() {
            reports += 1
            progress(ScanProgress(step: reports, processed: done, total: total, phase: phase, snapshot: result))
        }

        func step() {
            done += 1
            if done % reportInterval == 0 { report() }
        }

        // Photos: screenshots, blurry, and runs of similar shots.
        var group: [JunkItem] = []
        var previous: JunkItem?
        var previousPrint: VNFeaturePrintObservation?

        func closeGroup() {
            if group.count > 1 { result.similarGroups.append(group) }
            group = []
        }

        for index in 0..<photos.count {
            if Task.isCancelled { break }
            autoreleasepool {
                defer { step() }
                let asset = photos.object(at: index)

                if asset.mediaSubtypes.contains(.photoScreenshot) {
                    result.screenshots.append(JunkItem(asset: asset, bytes: Self.fileSize(of: asset)))
                    return
                }

                // Skip a photo only when no copy loads, for example iCloud with no network.
                guard let image = loadImage(asset) else {
                    closeGroup()
                    previous = nil
                    previousPrint = nil
                    return
                }

                let item = JunkItem(asset: asset, bytes: Self.fileSize(of: asset), sharpness: Self.sharpness(of: image))
                if let sharpness = item.sharpness, sharpness < blurThreshold {
                    result.blurry.append(item)
                }

                let print = Self.featurePrint(of: image)
                if let previous, isSimilar(asset, print, to: previous.asset, previousPrint) {
                    if group.isEmpty { group.append(previous) }
                    group.append(item)
                } else {
                    closeGroup()
                }
                previous = item
                previousPrint = print
            }
        }
        closeGroup()
        phase = .videos
        report()

        // Videos: large, short and screen recordings.
        for index in 0..<videos.count {
            if Task.isCancelled { break }
            defer { step() }
            let asset = videos.object(at: index)
            let item = JunkItem(asset: asset, bytes: Self.fileSize(of: asset))
            if item.bytes >= largeVideoBytes { result.largeVideos.append(item) }
            if asset.duration < shortVideoSeconds { result.shortVideos.append(item) }
            if asset.mediaSubtypes.contains(.videoScreenRecording) { result.screenRecordings.append(item) }
        }
        result.largeVideos.sort { $0.bytes > $1.bytes }

        phase = .finished
        report()
        return result
    }

    private func isSimilar(
        _ asset: PHAsset, _ print: VNFeaturePrintObservation?,
        to other: PHAsset, _ otherPrint: VNFeaturePrintObservation?
    ) -> Bool {
        guard let print, let otherPrint,
              let date = asset.creationDate, let otherDate = other.creationDate,
              abs(date.timeIntervalSince(otherDate)) <= similarityTimeWindow
        else { return false }
        var distance: Float = 0
        guard (try? print.computeDistance(&distance, to: otherPrint)) != nil else { return false }
        return distance <= similarityThreshold
    }

    /// Tries the copy on the device first. Downloads from iCloud only when no local copy loads.
    private func loadImage(_ asset: PHAsset) -> CGImage? {
        if let local = requestImage(asset, allowsNetwork: false) { return local }
        return downloadsFromICloud ? requestImage(asset, allowsNetwork: true) : nil
    }

    private func requestImage(_ asset: PHAsset, allowsNetwork: Bool) -> CGImage? {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = allowsNetwork
        var output: CGImage?
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: analysisSide, height: analysisSide),
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            output = image?.cgImage
        }
        return output
    }

    /// Counts the assets the scan leaves out: synced from a computer, shared albums and hidden.
    /// For finding why a library looks smaller than in the Photos app.
    static func logLibraryBreakdown() {
        func count(_ types: PHAssetSourceType, hidden: Bool = false) -> Int {
            let options = PHFetchOptions()
            options.includeAssetSourceTypes = types
            options.includeHiddenAssets = hidden
            return PHAsset.fetchAssets(with: options).count
        }
        let library = count(.typeUserLibrary)
        let hidden = count(.typeUserLibrary, hidden: true) - library
        log.info("Library: \(library, privacy: .public). Hidden: \(hidden, privacy: .public). Synced from a computer: \(count(.typeiTunesSynced), privacy: .public). Shared albums: \(count(.typeCloudShared), privacy: .public).")
    }

    /// Size on disk of all resources of the asset.
    /// Note: "fileSize" is not a public PHAssetResource API. It works today, but Apple can remove it.
    static func fileSize(of asset: PHAsset) -> Int64 {
        PHAssetResource.assetResources(for: asset).reduce(0) { sum, resource in
            sum + ((resource.value(forKey: "fileSize") as? NSNumber)?.int64Value ?? 0)
        }
    }

    static func featurePrint(of image: CGImage) -> VNFeaturePrintObservation? {
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: image)
        try? handler.perform([request])
        return request.results?.first
    }

    /// Variance of the Laplacian on a grayscale copy. Low values mean few sharp edges.
    static func sharpness(of image: CGImage) -> Double? {
        let width = image.width, height = image.height
        guard width > 2, height > 2 else { return nil }
        var pixels = [UInt8](repeating: 0, count: width * height)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }

        var sum = 0.0, sumOfSquares = 0.0
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let i = y * width + x
                let value = Int(pixels[i - 1]) + Int(pixels[i + 1])
                    + Int(pixels[i - width]) + Int(pixels[i + width])
                    - 4 * Int(pixels[i])
                let v = Double(value)
                sum += v
                sumOfSquares += v * v
            }
        }
        let count = Double((width - 2) * (height - 2))
        let mean = sum / count
        return sumOfSquares / count - mean * mean
    }
}
