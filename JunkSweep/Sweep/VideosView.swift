import Photos
import SwiftUI

/// Delete or keep each junk video. Matches design/design/Videos.dc.html.
/// The design also has Compress. It needs a video export step that is not built yet.
struct VideosView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.sweep) private var sweep
    @Environment(\.dismiss) private var dismiss

    @State private var filter: JunkCategory
    /// Every video starts as Delete, so the state stores the ones set to Keep.
    @State private var kept = Set<String>()

    init(category: JunkCategory) {
        _filter = State(initialValue: category)
    }

    private func videos(_ category: JunkCategory) -> [JunkItem] {
        store.result?.suggested(for: category) ?? []
    }

    /// Delete picks in every video category, each video once.
    private var plan: CleanPlan {
        CleanPlan(JunkCategory.videoCategories.map { category in
            (category, videos(category).filter { !kept.contains($0.id) })
        })
    }

    var body: some View {
        let all = JunkCategory.videoCategories.flatMap(videos).uniqued
        let plan = plan
        let deleting = plan.groups.flatMap(\.items)

        VStack(spacing: 14) {
            header
            VStack(alignment: .leading, spacing: 4) {
                Text("\(all.count.formatted()) \(all.count == 1 ? "video" : "videos") to sort")
                    .textStyle(.largeTitle)
                    .foregroundStyle(Palette.ink)
                Text("\(all.totalBytes.sizeLabel) · Delete or keep each one")
                    .textStyle(.callout)
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(JunkCategory.videoCategories) { category in
                        Button { filter = category } label: {
                            FilterChip(title: "\(category.chipTitle) · \(videos(category).count.formatted())",
                                       isSelected: filter == category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(videos(filter)) { video in
                        VideoCard(video: video, category: filter, isKept: Binding(
                            get: { kept.contains(video.id) },
                            set: { if $0 { kept.insert(video.id) } else { kept.remove(video.id) } }
                        ))
                    }
                }
                .padding(.horizontal, 16)
                // Room for the floating summary and button.
                .padding(.bottom, 130)
            }
            .scrollIndicators(.hidden)
            .overlay {
                if videos(filter).isEmpty {
                    Text("No \(filter.sweepTitle.lowercased()) found.")
                        .textStyle(.body)
                        .foregroundStyle(Palette.muted)
                }
            }
        }
        .padding(.top, 8)
        .background(Palette.background)
        .overlay(alignment: .bottom) {
            footer(deleting: deleting, keeping: all.count - deleting.count, plan: plan)
        }
        .ignoresSafeArea(edges: .bottom)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            RoundIconButton(systemImage: "chevron.left", label: "Back", iconWeight: .bold) { dismiss() }
            Spacer()
            RoundIconButton(systemImage: "line.3.horizontal.decrease", label: "Sort") {}
        }
        .frame(height: 44)
        .padding(.horizontal, 14)
    }

    private func footer(deleting: [JunkItem], keeping: Int, plan: CleanPlan) -> some View {
        VStack(spacing: 8) {
            Text("Delete \(deleting.count.formatted()) · Keep \(keeping.formatted())")
                .textStyle(.footnote)
                .foregroundStyle(Palette.inkSoft)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Palette.surface, in: Capsule())
                .shadow(css: 0.08, blur: 14, y: 4)
            PillButton(title: "Apply to \(deleting.count.formatted()) videos · free \(deleting.totalBytes.sizeLabel)",
                       kind: deleting.isEmpty ? .disabled : .primary) { sweep.confirm(plan) }
                .elevation(.floatingStrong)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 30)
    }
}

private struct VideoCard: View {
    let video: JunkItem
    let category: JunkCategory
    @Binding var isKept: Bool
    @State private var name: String?

    private var duration: String {
        Duration.seconds(video.asset.duration.rounded()).formatted(.time(pattern: .minuteSecond))
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                thumbnail
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(name ?? video.asset.creationDate?.formatted(date: .abbreviated, time: .omitted) ?? "Video")
                            .textStyle(.cardTitle)
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text(video.bytes.sizeLabel)
                            .textStyle(.calloutStrong)
                            .foregroundStyle(Palette.ink)
                            .fixedSize()
                    }
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                            .padding(.top, 2)
                        Text(category.detail)
                            .textStyle(.footnote)
                            .foregroundStyle(Palette.muted)
                            .lineSpacing(2)
                    }
                }
            }
            HStack(spacing: 4) {
                segment("Delete", isOn: !isKept, selectedColor: Palette.destructive) { isKept = false }
                segment("Keep", isOn: isKept, selectedColor: Palette.ink) { isKept = true }
            }
            .padding(3)
            .background(Palette.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Action for \(name ?? "video")")
        }
        .padding(10)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .elevation(.card)
        .task(id: video.id) {
            name = PHAssetResource.assetResources(for: video.asset).first?.originalFilename
        }
    }

    private var thumbnail: some View {
        AssetImage(asset: video.asset, side: 200)
            .overlay {
                Image(systemName: "play.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.92), in: Circle())
            }
            .overlay(alignment: .bottomTrailing) {
                Text(duration)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .padding(.vertical, 1)
                    .padding(.horizontal, 6)
                    .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 7))
                    .padding(5)
            }
            .frame(width: 84, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityHidden(true)
    }

    private func segment(_ title: String, isOn: Bool, selectedColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isOn ? selectedColor : Palette.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background {
                    if isOn {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(Palette.surface)
                            .shadow(css: 0.12, blur: 4, y: 1)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

#Preview {
    NavigationStack { VideosView(category: .largeVideos) }
        .environment(LibraryStore())
}
