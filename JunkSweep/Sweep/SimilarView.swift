import SwiftUI

/// One group of similar photos at a time. The sharpest photo is kept, the rest are marked.
/// Matches design/design/Similar.dc.html.
struct SimilarView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.sweep) private var sweep
    @Environment(\.dismiss) private var dismiss

    @State private var index = 0
    /// Photos the user tapped to keep, in any group.
    @State private var kept = Set<String>()
    @State private var applyToAllGroups = false

    private var groups: [[JunkItem]] { store.result?.similarGroups ?? [] }

    /// Photos to delete in a group: all but the best shot and the ones the user keeps.
    private func marked(in group: [JunkItem]) -> [JunkItem] {
        let bestID = group.best?.id
        return group.filter { $0.id != bestID && !kept.contains($0.id) }
    }

    var body: some View {
        let groups = groups
        VStack(spacing: 12) {
            header(groups.count)
            if groups.isEmpty {
                Spacer()
                Text("No similar shots found.")
                    .textStyle(.body)
                    .foregroundStyle(Palette.muted)
                Spacer()
            } else {
                content(groups[min(index, groups.count - 1)], all: groups)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 34)
        .background(Palette.background)
        .ignoresSafeArea(edges: .bottom)
        .toolbar(.hidden, for: .navigationBar)
        // Groups go away after a clean. Stay on a group that still exists.
        .onChange(of: groups.count) { _, count in index = min(index, max(count - 1, 0)) }
    }

    @ViewBuilder
    private func content(_ group: [JunkItem], all groups: [[JunkItem]]) -> some View {
        let best = group.best ?? group[0]
        let others = group.filter { $0.id != best.id }
        let marked = marked(in: group)

        BestShot(item: best)
        VStack(spacing: 2) {
            Text(best.asset.creationDate?.formatted(.dateTime.month(.abbreviated).day().year()) ?? "Similar shots")
                .textStyle(.sheetTitle)
                .foregroundStyle(Palette.ink)
            Text(subtitle(best, count: group.count))
                .textStyle(.callout)
                .foregroundStyle(Palette.muted)
        }
        .multilineTextAlignment(.center)

        // Sharpness is the only reason the scanner measures.
        Text("Sharpest")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Palette.surface, in: Capsule())

        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(marked.count) of \(others.count) marked to delete")
                    .textStyle(.bodyStrong)
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text("Tap to keep one")
                    .textStyle(.footnote)
                    .foregroundStyle(Palette.muted)
            }
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(others) { item in
                        ShotThumb(item: item, score: score(item, best: best), isMarked: !kept.contains(item.id)) {
                            if kept.contains(item.id) { kept.remove(item.id) } else { kept.insert(item.id) }
                        }
                        .containerRelativeFrame(.horizontal, count: 7, spacing: 6)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }

        let allMarked = groups.flatMap { self.marked(in: $0) }
        Toggle(isOn: $applyToAllGroups) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Apply to all \(groups.count.formatted()) groups")
                    .textStyle(.bodyStrong)
                    .foregroundStyle(Palette.ink)
                Text("Keep each best shot · frees \(allMarked.totalBytes.sizeLabel)")
                    .textStyle(.footnote)
                    .foregroundStyle(Palette.muted)
            }
        }
        .tint(Palette.accent)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

        Spacer(minLength: 0)

        HStack(spacing: 8) {
            Button { index = (index + 1) % groups.count } label: {
                Text("Skip")
                    .textStyle(.button)
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 20)
                    .frame(height: 54)
                    .background(Palette.surface, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(groups.count < 2)

            let items = applyToAllGroups ? allMarked : marked
            let title = applyToAllGroups
                ? "Clean \(groups.count.formatted()) groups · \(items.totalBytes.sizeLabel)"
                : "Delete \(items.count) · \(items.totalBytes.sizeLabel)"
            PillButton(title: title, kind: items.isEmpty ? .disabled : .primary, height: 54) {
                sweep.confirm(CleanPlan(.similar, items))
            }
        }
    }

    private func header(_ count: Int) -> some View {
        HStack {
            RoundIconButton(systemImage: "chevron.left", label: "Back", iconWeight: .bold) { dismiss() }
            Spacer()
            if count > 0 {
                Text("Group \(min(index, count - 1) + 1) of \(count.formatted())")
                    .textStyle(.bodyStrong)
                    .foregroundStyle(Palette.ink)
            }
            Spacer()
            RoundIconButton(systemImage: "ellipsis", label: "More options") {}
        }
        .frame(height: 44)
        .padding(.horizontal, -2)
    }

    private func subtitle(_ best: JunkItem, count: Int) -> String {
        let time = best.asset.creationDate?.formatted(date: .omitted, time: .shortened)
        return [time, "\(count) similar photos"].compactMap { $0 }.joined(separator: " · ")
    }

    /// Sharpness as a percent of the best shot's sharpness.
    private func score(_ item: JunkItem, best: JunkItem) -> String {
        guard let sharpness = item.sharpness, let top = best.sharpness, top > 0 else { return "–" }
        return "\(Int((min(sharpness / top, 1) * 100).rounded()))"
    }
}

/// Large photo of the best shot.
private struct BestShot: View {
    let item: JunkItem

    var body: some View {
        AssetImage(asset: item.asset, side: 1000)
            .overlay(alignment: .topLeading) {
                Label {
                    Text("AI best shot").textStyle(.footnoteStrong)
                } icon: {
                    Image(systemName: "sparkle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                }
                .labelStyle(TightLabelStyle(spacing: 6))
                .foregroundStyle(Palette.ink)
                .padding(.vertical, 7)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.94), in: Capsule())
                .padding(12)
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 40, height: 40)
                    .background(Palette.surface, in: Circle())
                    .padding(12)
            }
            .frame(height: 264)
            .photoFrame(cornerRadius: 30, border: 4)
            .shadow(css: 0.14, blur: 34, y: 14)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Best shot, kept")
            .accessibilityAddTraits(.isImage)
    }
}

private struct ShotThumb: View {
    let item: JunkItem
    let score: String
    let isMarked: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            AssetImage(asset: item.asset, side: 160)
                .frame(height: 62)
                .opacity(isMarked ? 0.7 : 1)
                .overlay(alignment: .topTrailing) {
                    if isMarked {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(Palette.ink, in: Circle())
                            .padding(3)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    Text(score)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .padding(.vertical, 1)
                        .padding(.horizontal, 5)
                        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 6))
                        .padding(3)
                }
                .overlay {
                    if !isMarked {
                        RoundedRectangle(cornerRadius: 13, style: .continuous).strokeBorder(Palette.accent, lineWidth: 3)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Photo, sharpness score \(score)")
        .accessibilityValue(isMarked ? "Will be deleted" : "Kept")
    }
}

#Preview {
    NavigationStack { SimilarView() }
        .environment(LibraryStore())
}
