import Photos
import SwiftUI

struct AssetThumbnail: View {
    let asset: PHAsset
    /// Requested size in pixels.
    var side: CGFloat = 300
    /// Fill a square cell, or fit the whole image.
    var fill = true

    @State private var image: UIImage?

    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.15))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: fill ? .fill : .fit)
                }
            }
            .clipped()
            .task(id: asset.localIdentifier) {
                image = await ThumbnailLoader.image(for: asset, side: side, fill: fill)
            }
    }
}

enum ThumbnailLoader {
    private static let manager = PHCachingImageManager()

    static func image(for asset: PHAsset, side: CGFloat, fill: Bool) async -> UIImage? {
        let options = PHImageRequestOptions()
        // highQualityFormat calls the handler exactly once, which the continuation needs.
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        return await withCheckedContinuation { continuation in
            manager.requestImage(
                for: asset,
                targetSize: CGSize(width: side, height: side),
                contentMode: fill ? .aspectFill : .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
