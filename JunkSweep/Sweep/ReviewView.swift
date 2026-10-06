import SwiftUI

/// Photo grid with bulk select for one category. Matches design/design/Review.dc.html.
struct ReviewView: View {
    enum Filter: CaseIterable { case all, older }

    let category: JunkCategory
    @Environment(LibraryStore.self) private var store
    @Environment(\.sweep) private var sweep
    @Environment(\.dismiss) private var dismiss

    /// Every suggestion starts selected, so the state stores what the user cleared.
    @State private var deselected = Set<String>()
    /// True after "Select all N suggested". Holds the selection to go back to on "Undo".
    @State private var bulkUndo: Set<String>?
    @State private var filter = Filter.all

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    private var suggested: [JunkItem] { store.result?.suggested(for: category) ?? [] }

    private var shown: [JunkItem] {
        guard filter == .older else { return suggested }
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: .now) ?? .now
        return suggested.filter { ($0.asset.creationDate ?? .now) < cutoff }
    }

    private var selectedItems: [JunkItem] { suggested.filter { !deselected.contains($0.id) } }

    var body: some View {
        let suggested = suggested
        let shown = shown
        let selected = selectedItems
        let allShownSelected = !shown.isEmpty && shown.allSatisfy { !deselected.contains($0.id) }

        VStack(spacing: 14) {
            header(count: suggested.count, bytes: suggested.totalBytes, allShownSelected: allShownSelected, shown: shown)
            chips
            aiNote
            bulkRow(selected: selected.count, suggested: suggested.count)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(shown) { item in
                        ReviewTile(item: item, isSelected: !deselected.contains(item.id)) { toggle(item) }
                    }
                }
                .padding(.horizontal, 16)
                // Room for the floating action bar.
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .overlay {
                if shown.isEmpty {
                    Text(filter == .older ? "Nothing older than 90 days." : "Nothing left to clean here.")
                        .textStyle(.body)
                        .foregroundStyle(Palette.muted)
                }
            }
        }
        .padding(.top, 8)
        .background(Palette.background)
        .overlay(alignment: .bottom) { actionBar(selected) }
        .ignoresSafeArea(edges: .bottom)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func toggle(_ item: JunkItem) {
        if deselected.contains(item.id) { deselected.remove(item.id) } else { deselected.insert(item.id) }
        bulkUndo = nil
    }

    private func header(count: Int, bytes: Int64, allShownSelected: Bool, shown: [JunkItem]) -> some View {
        HStack {
            RoundIconButton(systemImage: "chevron.left", label: "Back", iconWeight: .bold) { dismiss() }
                .padding(.leading, -2)
            Spacer()
            VStack(spacing: 0) {
                Text(category.sweepTitle)
                    .textStyle(.navTitle)
                    .foregroundStyle(Palette.ink)
                Text("\(count.itemsLabel) · \(bytes.sizeLabel)")
                    .textStyle(.caption)
                    .foregroundStyle(Palette.muted)
            }
            Spacer()
            Button {
                let ids = Set(shown.map(\.id))
                if allShownSelected { deselected.formUnion(ids) } else { deselected.subtract(ids) }
                bulkUndo = nil
            } label: {
                Text(allShownSelected ? "Deselect all" : "Select all")
                    .textStyle(.calloutStrong)
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .background(Palette.surface, in: Capsule())
                    .elevation(.button)
                    .frame(minHeight: 44)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(shown.isEmpty)
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }

    private var chips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                Button { filter = .all } label: {
                    FilterChip(title: "Safe to delete", isSelected: filter == .all)
                }
                Button { filter = .older } label: {
                    FilterChip(title: "Older than 90 days", isSelected: filter == .older)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }

    private var aiNote: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.accent)
                .frame(width: 36, height: 36)
                .background(Palette.accentSoft, in: Circle())
            (Text("\(category.detail). ")
                + Text("Tap a photo to keep it.")
                    .fontWeight(.semibold)
                    .foregroundColor(Palette.ink))
                .textStyle(.callout)
                .foregroundStyle(Palette.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .elevation(.card)
        .padding(.horizontal, 16)
    }

    private func bulkRow(selected: Int, suggested: Int) -> some View {
        HStack(spacing: 8) {
            if let undo = bulkUndo {
                Text("All \(suggested.formatted()) suggestions selected")
                    .textStyle(.calloutStrong)
                    .foregroundStyle(Palette.accent)
                Spacer()
                Button("Undo") {
                    deselected = undo
                    bulkUndo = nil
                }
                .textStyle(.calloutMedium)
                .foregroundStyle(Palette.muted)
                .padding(.horizontal, 4)
                .frame(minHeight: 32)
            } else {
                Text("\(selected.formatted()) selected")
                    .textStyle(.callout)
                    .foregroundStyle(Palette.muted)
                Spacer()
                if selected < suggested {
                    Button("Select all \(suggested.formatted()) suggested") {
                        bulkUndo = deselected
                        deselected = []
                    }
                    .textStyle(.calloutStrong)
                    .foregroundStyle(Palette.accent)
                    .padding(.horizontal, 4)
                    .frame(minHeight: 32)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: 32)
        .padding(.horizontal, 16)
    }

    private func actionBar(_ selected: [JunkItem]) -> some View {
        HStack(spacing: 8) {
            // Moving to an album needs an album picker, which is not in the design yet.
            Button {} label: {
                Image(systemName: "folder")
                    .font(.system(size: 19))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 56, height: 56)
                    .background(Palette.surface, in: Circle())
                    .elevation(.floating)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Move selected to an album")

            if selected.isEmpty {
                PillButton(title: "Select items to delete", kind: .disabled) {}
            } else {
                PillButton(title: "Delete \(selected.count.formatted()) · \(selected.totalBytes.sizeLabel)",
                           systemImage: "trash") { sweep.confirm(CleanPlan(category, selected)) }
                    .elevation(.floatingStrong)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 30)
    }
}

private struct ReviewTile: View {
    let item: JunkItem
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            AssetImage(asset: item.asset)
            .frame(height: 170)
            .overlay(alignment: .bottomLeading) {
                PhotoTag(text: item.bytes.sizeLabel).padding(7)
            }
            .overlay(alignment: .topTrailing) { checkmark.padding(7) }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.accent, lineWidth: 3)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accessibilityLabel: String {
        let date = item.asset.creationDate?.formatted(date: .abbreviated, time: .shortened) ?? "Photo"
        return "\(date), \(item.bytes.sizeLabel)"
    }

    @ViewBuilder private var checkmark: some View {
        if isSelected {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Palette.accent, in: Circle())
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
        } else {
            Circle()
                .fill(Palette.ink.opacity(0.18))
                .frame(width: 26, height: 26)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
        }
    }
}

#Preview {
    NavigationStack { ReviewView(category: .screenshots) }
        .environment(LibraryStore())
}
