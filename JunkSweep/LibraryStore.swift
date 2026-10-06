import Observation
import Photos

@MainActor
@Observable
final class LibraryStore {
    var authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    var isScanning = false
    var progress = 0.0
    /// Latest report of the current or last scan.
    var scanProgress: ScanProgress?
    var result: ScanResult?
    var errorMessage: String?

    private var scanWork: Task<ScanResult, Never>?
    private var lastStep = -1
    /// Items deleted while a scan runs. Later reports of that scan must not bring them back.
    private var deletedIDs = Set<String>()

    var hasAccess: Bool { authorization == .authorized || authorization == .limited }
    /// The user shared only some photos. A scan then sees only those.
    var hasLimitedAccess: Bool { authorization == .limited }

    /// Reads the access level again, for example after the user changes it in Settings.
    /// Returns true when access grew from limited to full.
    @discardableResult
    func refreshAuthorization() -> Bool {
        let old = authorization
        authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return old == .limited && authorization == .authorized
    }

    func requestAccess() async {
        authorization = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    /// Starts a scan when none is running.
    func startScan() {
        guard !isScanning else { return }
        Task { await scan() }
    }

    /// Stops the scan and keeps what it found so far.
    func cancelScan() {
        scanWork?.cancel()
    }

    func scan() async {
        guard !isScanning else { return }
        isScanning = true
        progress = 0
        scanProgress = nil
        lastStep = -1
        deletedIDs = []
        // On a first scan, show results as they come. On a new scan, keep the old results until it ends.
        let showsPartialResults = result == nil

        let scanner = JunkScanner()
        let work = Task.detached(priority: .userInitiated) { [weak self] in
            scanner.scan { update in
                Task { @MainActor in self?.apply(update, showsPartialResults: showsPartialResults) }
            }
        }
        scanWork = work
        var final = await work.value
        final.remove(ids: deletedIDs)

        // Drop reports that are still on their way.
        lastStep = .max
        result = final
        scanProgress?.snapshot = final
        scanProgress?.phase = .finished
        progress = 1
        scanWork = nil
        isScanning = false
    }

    private func apply(_ update: ScanProgress, showsPartialResults: Bool) {
        guard update.step > lastStep else { return }
        lastStep = update.step
        var update = update
        update.snapshot.remove(ids: deletedIDs)
        scanProgress = update
        progress = update.fraction
        if showsPartialResults { result = update.snapshot }
    }

    /// Deletes all items in one change. iOS asks the user to confirm once for the whole batch.
    /// Deleted items go to "Recently Deleted" in the Photos app.
    @discardableResult
    func delete(_ items: [JunkItem]) async -> Bool {
        guard !items.isEmpty else { return false }
        let assets = items.map(\.asset) as NSArray
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets)
            }
        } catch {
            if (error as? PHPhotosError)?.code != .userCancelled {
                errorMessage = error.localizedDescription
            }
            return false
        }
        let ids = Set(items.map(\.id))
        if isScanning { deletedIDs.formUnion(ids) }
        result?.remove(ids: ids)
        return true
    }
}

/// Space on the device volume.
struct StorageInfo {
    let usedBytes: Int64
    let totalBytes: Int64

    static func current() -> StorageInfo? {
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        guard let values = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: keys),
              let total = values.volumeTotalCapacity,
              let available = values.volumeAvailableCapacityForImportantUsage
        else { return nil }
        return StorageInfo(usedBytes: Int64(total) - available, totalBytes: Int64(total))
    }
}
