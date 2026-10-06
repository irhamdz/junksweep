import Photos

enum JunkCategory: String, CaseIterable, Identifiable, Hashable {
    case screenshots, similar, blurry, largeVideos, shortVideos, screenRecordings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .screenshots: "Screenshots"
        case .similar: "Similar Photos"
        case .blurry: "Blurry Photos"
        case .largeVideos: "Large Videos"
        case .shortVideos: "Short Videos"
        case .screenRecordings: "Screen Recordings"
        }
    }

    var detail: String {
        switch self {
        case .screenshots: "All screenshots in your library"
        case .similar: "Near-duplicate shots taken close together"
        case .blurry: "Photos that look out of focus"
        case .largeVideos: "Videos of 100 MB or more"
        case .shortVideos: "Videos shorter than 3 seconds"
        case .screenRecordings: "Recordings of your screen"
        }
    }

    var systemImage: String {
        switch self {
        case .screenshots: "camera.viewfinder"
        case .similar: "square.on.square"
        case .blurry: "eye.slash"
        case .largeVideos: "film"
        case .shortVideos: "timer"
        case .screenRecordings: "record.circle"
        }
    }
}

struct JunkItem: Identifiable, Hashable {
    let asset: PHAsset
    let bytes: Int64
    /// Laplacian variance of a small grayscale copy. Higher means sharper. Only set for scanned photos.
    var sharpness: Double?

    var id: String { asset.localIdentifier }

    static func == (lhs: JunkItem, rhs: JunkItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension Array where Element == JunkItem {
    /// Sum of sizes, counting each asset once.
    var totalBytes: Int64 {
        var seen = Set<String>()
        return reduce(0) { sum, item in seen.insert(item.id).inserted ? sum + item.bytes : sum }
    }

    /// The same items with each asset once, in the original order.
    var uniqued: [JunkItem] {
        var seen = Set<String>()
        return filter { seen.insert($0.id).inserted }
    }

    /// The sharpest photo. Used as the one to keep in a group of similar photos.
    var best: JunkItem? {
        self.max { ($0.sharpness ?? 0) < ($1.sharpness ?? 0) }
    }
}

struct ScanResult {
    var screenshots: [JunkItem] = []
    var similarGroups: [[JunkItem]] = []
    var blurry: [JunkItem] = []
    var largeVideos: [JunkItem] = []
    var shortVideos: [JunkItem] = []
    var screenRecordings: [JunkItem] = []

    func items(for category: JunkCategory) -> [JunkItem] {
        switch category {
        case .screenshots: screenshots
        case .similar: similarGroups.flatMap { $0 }
        case .blurry: blurry
        case .largeVideos: largeVideos
        case .shortVideos: shortVideos
        case .screenRecordings: screenRecordings
        }
    }

    /// Items to delete by default. For similar photos, this keeps the sharpest photo of each group.
    func suggested(for category: JunkCategory) -> [JunkItem] {
        guard category == .similar else { return items(for: category) }
        return similarGroups.flatMap { group in
            let bestID = group.best?.id
            return group.filter { $0.id != bestID }
        }
    }

    var totalBytes: Int64 {
        JunkCategory.allCases.flatMap { items(for: $0) }.totalBytes
    }

    mutating func remove(ids: Set<String>) {
        screenshots.removeAll { ids.contains($0.id) }
        blurry.removeAll { ids.contains($0.id) }
        largeVideos.removeAll { ids.contains($0.id) }
        shortVideos.removeAll { ids.contains($0.id) }
        screenRecordings.removeAll { ids.contains($0.id) }
        similarGroups = similarGroups
            .map { $0.filter { !ids.contains($0.id) } }
            .filter { $0.count > 1 }
    }
}

extension Int64 {
    var formattedBytes: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}
