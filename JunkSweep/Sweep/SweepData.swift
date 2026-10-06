import Photos
import SwiftUI

// Maps LibraryStore results to what the Sweep screens show.

enum SweepRoute: Hashable {
    case scanning
    case review(JunkCategory)
    case similar
    case videos(JunkCategory)
    case done(CleanResult)
}

/// What the Confirm sheet cleaned. The Done screen shows it.
struct CleanResult: Hashable {
    let items: Int
    let bytes: Int64
}

/// Items the Confirm sheet offers to delete, one row per category.
struct CleanPlan: Identifiable {
    struct Group: Identifiable {
        let category: JunkCategory
        let items: [JunkItem]
        var id: JunkCategory { category }
    }

    let id = UUID()
    let groups: [Group]

    /// Drops empty groups, and items that an earlier group already has.
    init(_ groups: [(JunkCategory, [JunkItem])]) {
        var seen = Set<String>()
        self.groups = groups.compactMap { category, items in
            let fresh = items.filter { seen.insert($0.id).inserted }
            return fresh.isEmpty ? nil : Group(category: category, items: fresh)
        }
    }

    init(_ category: JunkCategory, _ items: [JunkItem]) {
        self.init([(category, items)])
    }

    /// Every suggestion in every category. Used by "Clean all suggested".
    static func allSuggested(in result: ScanResult) -> CleanPlan {
        CleanPlan(JunkCategory.sweepOrder.map { ($0, result.suggested(for: $0)) })
    }
}

/// Screen actions. SweepRootView sets them.
struct SweepNavigator {
    var open: (SweepRoute) -> Void = { _ in }
    var confirm: (CleanPlan) -> Void = { _ in }
}

extension EnvironmentValues {
    @Entry var sweep = SweepNavigator()
}

extension JunkCategory {
    /// Order of the category cards and Confirm rows. Similar comes first on Home as the large card.
    static let sweepOrder: [JunkCategory] = [.screenshots, .similar, .blurry, .largeVideos, .shortVideos, .screenRecordings]
    static let videoCategories: [JunkCategory] = [.largeVideos, .shortVideos, .screenRecordings]

    var sweepTitle: String {
        switch self {
        case .screenshots: "Screenshots"
        case .similar: "Similar shots"
        case .blurry: "Blurry photos"
        case .largeVideos: "Large videos"
        case .shortVideos: "Accidental clips"
        case .screenRecordings: "Screen recordings"
        }
    }

    /// Short name for the filter chips on Videos.
    var chipTitle: String {
        switch self {
        case .largeVideos: "Large"
        case .shortVideos: "Accidental"
        case .screenRecordings: "Screen rec"
        default: sweepTitle
        }
    }

    var tint: Color {
        switch self {
        case .screenshots: Palette.Tint.screenshots
        case .similar: Palette.Tint.similar
        case .blurry: Palette.Tint.blurry
        case .largeVideos: Palette.Tint.largeVideos
        case .shortVideos: Palette.Tint.accidental
        case .screenRecordings: Palette.Tint.screenRecordings
        }
    }

    var isVideo: Bool { Self.videoCategories.contains(self) }

    /// Extra text on the Confirm row.
    var confirmNote: String? { self == .similar ? "best of each kept" : nil }

    var route: SweepRoute {
        switch self {
        case .similar: .similar
        case .largeVideos, .shortVideos, .screenRecordings: .videos(self)
        case .screenshots, .blurry: .review(self)
        }
    }

    func countLabel(_ count: Int) -> String {
        let noun = isVideo ? (count == 1 ? "video" : "videos")
            : self == .similar ? (count == 1 ? "photo" : "photos")
            : (count == 1 ? "item" : "items")
        return "\(count.formatted()) \(noun)"
    }
}

extension Int {
    /// "1 item" or "4,791 items".
    var itemsLabel: String { "\(formatted()) \(self == 1 ? "item" : "items")" }
}

extension Int64 {
    /// "0.4 MB", "312 MB" or "2.4 GB". Megabytes below 1 GB, so small sizes never show as "0.0 GB".
    var sizeLabel: String {
        let megabytes = Double(self) / 1e6
        if megabytes >= 999.5 {
            return "\((megabytes / 1000).formatted(.number.precision(.fractionLength(1)))) GB"
        }
        if megabytes < 10 {
            // Show at least 0.1 MB for a file that is not empty.
            let shown = self > 0 ? Swift.max(megabytes, 0.1) : 0
            return "\(shown.formatted(.number.precision(.fractionLength(0...1)))) MB"
        }
        return "\(Int(megabytes.rounded()).formatted()) MB"
    }

    /// "112" or "92.6" gigabytes, for "112 of 128 GB".
    var gigabytesValue: String {
        let value = Double(self) / 1e9
        return value >= 100
            ? value.formatted(.number.precision(.fractionLength(0)))
            : value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

extension StorageInfo {
    /// "112 of 128 GB".
    var usedLabel: String { "\(usedBytes.gigabytesValue) of \(totalBytes.gigabytesValue) GB" }
}

// MARK: - Photos

/// Photo from the library that fills its frame. Grey until it loads.
struct AssetImage: View {
    let asset: PHAsset
    /// Requested size in pixels.
    var side: CGFloat = 300

    @State private var image: UIImage?

    var body: some View {
        Color(hex: 0xE6E8EC)
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .clipped()
            .task(id: asset.localIdentifier) {
                image = await ThumbnailLoader.image(for: asset, side: side, fill: true)
            }
    }
}
