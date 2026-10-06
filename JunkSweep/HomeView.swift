import SwiftUI

struct HomeView: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.hasAccess {
                    content
                } else {
                    AccessView()
                }
            }
            .navigationTitle("JunkSweep")
            .navigationDestination(for: JunkCategory.self) { CategoryView(category: $0) }
        }
    }

    private var content: some View {
        List {
            Section {
                summary
            }
            if let result = store.result {
                Section("Categories") {
                    ForEach(JunkCategory.allCases) { category in
                        let items = result.items(for: category)
                        NavigationLink(value: category) {
                            CategoryRow(category: category, count: items.count, bytes: items.totalBytes)
                        }
                    }
                }
            }
        }
    }

    private var summary: some View {
        VStack(spacing: 12) {
            if let result = store.result {
                Text(result.totalBytes.formattedBytes)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("of junk found")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)
                Text("Scan your library to find screenshots, similar and blurry photos, and junk videos.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            if store.isScanning {
                ProgressView(value: store.progress)
                Text("Scanning… \(Int(store.progress * 100))%")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Button(store.result == nil ? "Scan Library" : "Scan Again") {
                    Task { await store.scan() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
}

private struct CategoryRow: View {
    let category: JunkCategory
    let count: Int
    let bytes: Int64

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.title).font(.headline)
                Text(category.detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(count)").font(.headline)
                Text(bytes.formattedBytes).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AccessView: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        ContentUnavailableView {
            Label("Photo Access Needed", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("JunkSweep needs access to your photos to find junk. Nothing leaves your device.")
        } actions: {
            if store.authorization == .notDetermined {
                Button("Allow Access") {
                    Task { await store.requestAccess() }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
