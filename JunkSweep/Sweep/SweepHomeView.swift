import Photos
import SwiftUI

/// Home screen. Matches design/design/Main.dc.html.
struct SweepHomeView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.sweep) private var sweep
    @State private var storage = StorageInfo.current()

    private var cards: [CategoryCardInfo] {
        guard let result = store.result else { return [] }
        return JunkCategory.sweepOrder.map { CategoryCardInfo(category: $0, result: result) }
    }

    var body: some View {
        let cards = cards
        ScrollView {
            VStack(spacing: 0) {
                header
                HeroStack()
                    .padding(.top, 18)
                if let result = store.result {
                    summary(result)
                        .padding(.top, 18)
                    PillButton(title: "Clean all suggested", kind: cards.contains { $0.count > 0 } ? .accent : .disabled,
                               height: 48, horizontalPadding: 28, fillsWidth: false) {
                        sweep.confirm(.allSuggested(in: result))
                    }
                    .padding(.top, 18)
                    if store.hasLimitedAccess {
                        limitedAccessCard
                            .padding(.top, 18)
                    }
                    sectionHeader
                        .padding(.top, 40)
                    if let similar = cards.first(where: { $0.category == .similar }) {
                        FeatureCard(info: similar) { sweep.open(.similar) }
                            .padding(.top, 14)
                    }
                    categoryGrid(cards.filter { $0.category != .similar })
                        .padding(.top, 26)
                } else {
                    emptyState
                        .padding(.top, 18)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            // Room for the floating tab bar.
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .background(Palette.background)
        .overlay(alignment: .bottom) {
            HStack(alignment: .bottom) {
                TabBar()
                Spacer()
                Button(action: scan) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Palette.ink, in: Circle())
                        .elevation(.floatingStrong)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Scan library")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: store.isScanning) { storage = StorageInfo.current() }
    }

    private func scan() {
        store.startScan()
        sweep.open(.scanning)
    }

    private var header: some View {
        HStack {
            Button {} label: {
                Image(systemName: "person")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Palette.muted)
                    .frame(width: 40, height: 40)
                    .background(Palette.disabled, in: Circle())
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                    .shadow(css: 0.08, blur: 8, y: 2)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Profile")

            Spacer()

            HStack(spacing: 8) {
                RoundIconButton(systemImage: "magnifyingglass", label: "Search") {}
                RoundIconButton(systemImage: "line.3.horizontal.decrease", label: "Filter") {}
            }
            // 44 pt touch targets overlap by 4 pt so the 40 pt circles keep an 8 pt gap.
            .padding(.trailing, -2)
        }
        .frame(height: 44)
        .padding(.leading, -2)
    }

    private func summary(_ result: ScanResult) -> some View {
        let suggested = JunkCategory.sweepOrder.flatMap { result.suggested(for: $0) }.uniqued
        let subtitle = store.isScanning
            ? "\(suggested.count.itemsLabel) so far · scanning \(Int(store.progress * 100))%"
            : "\(suggested.count.itemsLabel) · sorted by on-device AI"
        return VStack(spacing: 6) {
            Text("\(suggested.totalBytes.sizeLabel) of junk found")
                .textStyle(.title)
                .foregroundStyle(Palette.ink)
            Text(subtitle)
                .textStyle(.body)
                .foregroundStyle(Palette.muted)
        }
        .multilineTextAlignment(.center)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Scan your library")
                    .textStyle(.title)
                    .foregroundStyle(Palette.ink)
                Text("Find screenshots, similar shots, blurry photos and junk videos.")
                    .textStyle(.body)
                    .foregroundStyle(Palette.muted)
            }
            .multilineTextAlignment(.center)
            PillButton(title: "Scan library", kind: .accent, height: 48, horizontalPadding: 28, fillsWidth: false,
                       action: scan)
        }
    }

    /// With limited access, the scan sees only the photos the user shared.
    private var limitedAccessCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.accent)
                .frame(width: 40, height: 40)
                .background(Palette.accentSoft, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Only some photos are scanned")
                    .textStyle(.bodyStrong)
                    .foregroundStyle(Palette.ink)
                Text("Allow full access to scan your whole library.")
                    .textStyle(.footnote)
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Settings")
                    .textStyle(.calloutStrong)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .background(Palette.ink, in: Capsule())
                    .frame(minHeight: 44)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var sectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Sorted by AI")
                .textStyle(.section)
                .foregroundStyle(Palette.ink)
            Spacer()
            if let storage {
                Text("\(storage.usedLabel) used")
                    .textStyle(.footnote)
                    .foregroundStyle(Palette.muted)
            }
        }
    }

    private func categoryGrid(_ cards: [CategoryCardInfo]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                  spacing: 22) {
            ForEach(cards) { card in
                CategoryCard(info: card) { sweep.open(card.category.route) }
            }
        }
    }
}

/// Count, size and preview photos of one category.
private struct CategoryCardInfo: Identifiable {
    let category: JunkCategory
    let count: Int
    let bytes: Int64
    let previews: [PHAsset]

    var id: JunkCategory { category }

    init(category: JunkCategory, result: ScanResult) {
        let suggested = result.suggested(for: category)
        self.category = category
        count = suggested.count
        bytes = suggested.totalBytes
        // For similar shots, preview the photo each group keeps.
        let previewItems = category == .similar ? result.similarGroups.compactMap(\.best) : suggested
        previews = previewItems.prefix(category == .similar ? 4 : 3).map(\.asset)
    }

    var meta: String { count == 0 ? "None found" : category.countLabel(count) }
}

// MARK: - Hero

/// Three tilted cards: a pocket video, a blurry photo and an expired OTP screenshot.
private struct HeroStack: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            heroPhoto(scene: .night, sunX: 0.62, sunY: 0.16, sunWidth: 0.22, groundHeight: 0.34, label: "0:48 · pocket")
                .rotationEffect(.degrees(9))
                .offset(x: 196, y: 22)

            heroPhoto(scene: .blossom, sunX: 0.18, sunY: 0.14, sunWidth: 0.46, groundHeight: 0.38, blur: 4, label: "Blurry")
                .rotationEffect(.degrees(-10))
                .offset(x: 46, y: 26)

            otpCard
                .rotationEffect(.degrees(-2))
                .offset(x: 118, y: 44)
        }
        .frame(width: 358, height: 236, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    private func heroPhoto(scene: PhotoScene, sunX: CGFloat, sunY: CGFloat, sunWidth: CGFloat,
                           groundHeight: CGFloat, blur: CGFloat = 0, label: String) -> some View {
        ScenePhoto(scene: scene, sunX: sunX, sunY: sunY, sunWidth: sunWidth, groundHeight: groundHeight, blur: blur)
            .overlay(alignment: .bottomLeading) {
                PhotoTag(text: label, padding: EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                    .padding(10)
            }
            .frame(width: 124, height: 168)
            .photoFrame(cornerRadius: 20, border: 4)
            .shadow(css: 0.16, blur: 30, y: 12)
    }

    private var otpCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Capsule().fill(Palette.switchOff).frame(width: 55, height: 7)
            Text("482 913")
                .font(.system(size: 18, weight: .bold))
                .tracking(18 * 0.18)
                .foregroundStyle(Palette.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: 10))
            Capsule().fill(Color(hex: 0xE6E8EC)).frame(width: 95, height: 6)
            Capsule().fill(Color(hex: 0xE6E8EC)).frame(width: 77, height: 6)
            Spacer(minLength: 0)
            PhotoTag(text: "OTP · expired", dark: true, padding: EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 14)
        .frame(width: 138, height: 180)
        .background(.white)
        .photoFrame(cornerRadius: 22, border: 4)
        .shadow(css: 0.2, blur: 36, y: 16)
    }
}

// MARK: - Category cards

private struct FeatureCard: View {
    let info: CategoryCardInfo
    let action: () -> Void

    private let lefts: [CGFloat] = [10, 94, 178, 262]
    private let angles: [Double] = [-4, 2, -2, 4]

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topLeading) {
                    info.category.tint
                    ForEach(info.previews.indices, id: \.self) { i in
                        AssetImage(asset: info.previews[i], side: 260)
                            .frame(width: 80, height: 122)
                            .photoFrame(cornerRadius: 18, border: 3)
                            .rotationEffect(.degrees(angles[i]))
                            .offset(x: lefts[i], y: 10)
                    }
                    FrostedStrip(cornerRadius: 22)
                        .frame(height: 76)
                        .padding(8)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    HStack {
                        Label {
                            Text("AI keeps the best of each").textStyle(.footnoteStrong)
                        } icon: {
                            Image(systemName: "sparkle").font(.system(size: 13, weight: .semibold))
                        }
                        .labelStyle(TightLabelStyle(spacing: 6))
                        .foregroundStyle(Palette.ink)
                        Spacer()
                        CardArrow(size: 44)
                    }
                    .padding(.leading, 24)
                    .padding(.trailing, 22)
                    .padding(.bottom, 24)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .frame(height: 172)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                Text(info.category.sweepTitle)
                    .textStyle(.section)
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 10)
                Text(info.count == 0 ? info.meta : "\(info.meta) · \(info.bytes.sizeLabel)")
                    .textStyle(.callout)
                    .foregroundStyle(Palette.muted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(info.count == 0)
    }
}

private struct CategoryCard: View {
    let info: CategoryCardInfo
    let action: () -> Void

    private let lefts: [CGFloat] = [8, 56, 104]
    private let angles: [Double] = [-5, 0, 5]

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ZStack(alignment: .topLeading) {
                    info.category.tint
                    ForEach(info.previews.indices, id: \.self) { i in
                        AssetImage(asset: info.previews[i], side: 180)
                            .frame(width: 54, height: 86)
                            .photoFrame(cornerRadius: 14, border: 3)
                            .rotationEffect(.degrees(angles[i]))
                            .offset(x: lefts[i], y: 10)
                    }
                    FrostedStrip(cornerRadius: 18, tint: 0.24)
                        .frame(height: 54)
                        .padding(6)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    HStack {
                        Text(info.bytes.sizeLabel)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        CardArrow(size: 34)
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 14)
                    .padding(.bottom, 15)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .frame(height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                Text(info.category.sweepTitle)
                    .textStyle(.cardTitle)
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 8)
                Text(info.meta)
                    .textStyle(.footnote)
                    .foregroundStyle(Palette.muted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(info.count == 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(info.category.sweepTitle), \(info.meta), \(info.bytes.sizeLabel)")
    }
}

struct TightLabelStyle: LabelStyle {
    let spacing: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: spacing) {
            configuration.icon
            configuration.title
        }
    }
}

// MARK: - Tab bar

private struct TabBar: View {
    var body: some View {
        HStack(spacing: 4) {
            tab("sparkle", label: "Clean", selected: true)
            tab("square.grid.2x2", label: "Library")
            tab("chart.bar.xaxis", label: "Insights, 1 new")
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Palette.badge)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .padding(9)
                }
        }
        .padding(6)
        .background(Palette.surface, in: Capsule())
        .elevation(.floating)
    }

    // Library and Insights are not in the design set yet, so they have no action.
    private func tab(_ systemImage: String, label: String, selected: Bool = false) -> some View {
        Button {} label: {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? .white : Palette.muted)
                .frame(width: 44, height: 44)
                .background(selected ? Palette.ink : .clear, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview {
    SweepHomeView().environment(LibraryStore())
}
