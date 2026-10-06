import SwiftUI

/// Result after a clean. Matches design/design/Done.dc.html.
struct DoneView: View {
    let result: CleanResult
    let finish: () -> Void
    // Not connected yet: there is no background scan or notification.
    @State private var weeklyScan = true
    /// Read once. Deleted items still use space until Recently Deleted is emptied.
    @State private var storage = StorageInfo.current()

    var body: some View {
        VStack(spacing: 14) {
            hero
            VStack(spacing: 4) {
                Text("\(result.bytes.sizeLabel) cleaned")
                    .textStyle(.display)
                    .foregroundStyle(Palette.ink)
                Text("\(result.items.itemsLabel) moved to Recently Deleted")
                    .textStyle(.body)
                    .foregroundStyle(Palette.muted)
            }
            .multilineTextAlignment(.center)

            if let storage { storageCard(storage) }

            actionCard(systemImage: "trash", iconBackground: Palette.Tint.largeVideos, iconColor: Color(hex: 0x5C3A00),
                       title: "Free it up now", detail: "iOS holds deleted items for 30 days") {
                // PhotoKit has no API to empty Recently Deleted, so this needs a design decision.
                Button {} label: {
                    Text("Empty")
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

            actionCard(systemImage: "sparkle", iconBackground: Palette.accentSoft, iconColor: Palette.accent,
                       title: "Weekly AI scan", detail: "Nudge me when junk passes 2 GB") {
                Toggle("Weekly AI scan", isOn: $weeklyScan)
                    .labelsHidden()
                    .tint(Palette.accent)
            }

            Spacer(minLength: 0)

            PillButton(title: "Done", action: finish)
        }
        .padding(.horizontal, 16)
        .padding(.top, 25)
        .padding(.bottom, 34)
        .background(Palette.background)
        .ignoresSafeArea(edges: .bottom)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var hero: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: 0xE6E8EC))
                .frame(width: 104, height: 140)
                .photoFrame(cornerRadius: 20, border: 4)
                .rotationEffect(.degrees(-10))
                .offset(x: 18, y: 22)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: 0xE6E8EC))
                .frame(width: 104, height: 140)
                .photoFrame(cornerRadius: 20, border: 4)
                .rotationEffect(.degrees(9))
                .offset(x: 118, y: 18)
            Image(systemName: "checkmark")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Palette.accent, in: Circle())
                .frame(width: 112, height: 150)
                .background(.white)
                .photoFrame(cornerRadius: 22, border: 4)
                .shadow(css: 0.14, blur: 32, y: 14)
                .rotationEffect(.degrees(-2))
                .offset(x: 64, y: 28)
        }
        .frame(width: 240, height: 186, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    private func storageCard(_ storage: StorageInfo) -> some View {
        let after = StorageInfo(usedBytes: max(0, storage.usedBytes - result.bytes), totalBytes: storage.totalBytes)
        return VStack(spacing: 12) {
            StorageBar(label: "Before", value: storage.usedLabel,
                       fraction: Double(storage.usedBytes) / Double(max(storage.totalBytes, 1)),
                       color: Color(hex: 0x9AA0A8))
            StorageBar(label: "After emptying", value: after.usedLabel,
                       fraction: Double(after.usedBytes) / Double(max(after.totalBytes, 1)),
                       color: Palette.accent)
        }
        .padding(16)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func actionCard<Accessory: View>(systemImage: String, iconBackground: Color, iconColor: Color,
                                             title: String, detail: String,
                                             @ViewBuilder accessory: () -> Accessory) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(iconBackground, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .textStyle(.bodyStrong)
                    .foregroundStyle(Palette.ink)
                Text(detail)
                    .textStyle(.footnote)
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            accessory()
        }
        .padding(14)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct StorageBar: View {
    let label: String
    let value: String
    let fraction: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label).foregroundStyle(Palette.muted)
                Spacer()
                Text(value).fontWeight(.semibold).foregroundStyle(Palette.ink)
            }
            .textStyle(.footnote)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.background)
                    Capsule().fill(color).frame(width: geo.size.width * min(max(fraction, 0), 1))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { DoneView(result: CleanResult(items: 4791, bytes: 19_400_000_000)) {} }
}
