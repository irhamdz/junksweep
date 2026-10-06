import SwiftUI

struct CategoryView: View {
    let category: JunkCategory
    @Environment(LibraryStore.self) private var store
    @State private var selection = Set<String>()
    @State private var isDeleting = false

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]

    private var items: [JunkItem] { store.result?.items(for: category) ?? [] }
    private var groups: [[JunkItem]] { store.result?.similarGroups ?? [] }

    /// For similar photos, "select all" keeps the sharpest photo of each group.
    private var selectAllIDs: Set<String> {
        if category == .similar {
            return Set(groups.flatMap { group in group.filter { $0.id != best(in: group)?.id } }.map(\.id))
        }
        return Set(items.map(\.id))
    }

    private var allSelected: Bool {
        !selectAllIDs.isEmpty && selectAllIDs.isSubset(of: selection)
    }

    private var selectedItems: [JunkItem] {
        items.filter { selection.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            if category == .similar {
                similarGrid
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(items) { cell($0) }
                }
            }
        }
        .overlay {
            if items.isEmpty {
                ContentUnavailableView(
                    "All Clean",
                    systemImage: "checkmark.circle",
                    description: Text("No \(category.title.lowercased()) found.")
                )
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(allSelected ? "Deselect All" : (category == .similar ? "Select Extras" : "Select All")) {
                    selection = allSelected ? [] : selectAllIDs
                }
                .disabled(items.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !selection.isEmpty { deleteBar }
        }
        .alert(
            "Could Not Delete",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var similarGrid: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ForEach(groups, id: \.first?.id) { group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(group.count) similar photos").font(.headline)
                        Spacer()
                        Button("Keep Best") { keepBest(in: group) }
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                    LazyVGrid(columns: columns, spacing: 2) {
                        let bestID = best(in: group)?.id
                        ForEach(group) { cell($0, isBest: $0.id == bestID) }
                    }
                }
            }
        }
        .padding(.vertical)
    }

    private func cell(_ item: JunkItem, isBest: Bool = false) -> some View {
        let isSelected = selection.contains(item.id)
        return AssetThumbnail(asset: item.asset)
            .overlay {
                if isSelected { Color.black.opacity(0.3) }
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : .white)
                    .background(Circle().fill(isSelected ? .white : .clear).padding(2))
                    .shadow(radius: 2)
                    .padding(6)
            }
            .overlay(alignment: .bottomLeading) {
                badge(for: item, isBest: isBest)
            }
            .contentShape(Rectangle())
            .onTapGesture { toggle(item) }
            .contextMenu {
                Button(isSelected ? "Deselect" : "Select", systemImage: isSelected ? "circle" : "checkmark.circle") {
                    toggle(item)
                }
            } preview: {
                AssetThumbnail(asset: item.asset, side: 1000, fill: false)
                    .frame(width: 340, height: 340)
            }
    }

    private func badge(for item: JunkItem, isBest: Bool) -> some View {
        HStack(spacing: 4) {
            if isBest { Image(systemName: "star.fill") }
            if item.asset.mediaType == .video {
                Text(Duration.seconds(item.asset.duration).formatted(.time(pattern: .minuteSecond)))
            } else {
                Text(item.bytes.formattedBytes)
            }
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.black.opacity(0.55), in: Capsule())
        .padding(5)
    }

    private var deleteBar: some View {
        Button(role: .destructive) {
            Task {
                isDeleting = true
                if await store.delete(selectedItems) { selection.removeAll() }
                isDeleting = false
            }
        } label: {
            Label(
                "Delete \(selection.count) (\(selectedItems.totalBytes.formattedBytes))",
                systemImage: "trash"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .controlSize(.large)
        .disabled(isDeleting)
        .padding()
        .background(.bar)
    }

    private func toggle(_ item: JunkItem) {
        if selection.contains(item.id) {
            selection.remove(item.id)
        } else {
            selection.insert(item.id)
        }
    }

    private func best(in group: [JunkItem]) -> JunkItem? {
        group.max { ($0.sharpness ?? 0) < ($1.sharpness ?? 0) }
    }

    private func keepBest(in group: [JunkItem]) {
        let bestID = best(in: group)?.id
        for item in group {
            if item.id == bestID {
                selection.remove(item.id)
            } else {
                selection.insert(item.id)
            }
        }
    }
}
