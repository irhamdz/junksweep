import SwiftUI

/// Navigation for the Sweep design. Flow from design/HANDOFF.md:
/// Scanning → Home → Review / Similar / Videos → Confirm (sheet) → Done → Home.
struct SweepRootView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var path: [SweepRoute] = []
    @State private var plan: CleanPlan?

    var body: some View {
        Group {
            if store.hasAccess {
                stack
            } else {
                AccessView()
            }
        }
        .preferredColorScheme(.light)
        .task(id: store.hasAccess) { startFirstScan() }
        // The user can change photo access in Settings. With full access, scan the whole library.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, store.refreshAuthorization() else { return }
            store.startScan()
            path = [.scanning]
        }
        .alert(
            "Could not delete",
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

    private var stack: some View {
        NavigationStack(path: $path) {
            SweepHomeView()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: SweepRoute.self) { route in
                    switch route {
                    case .scanning: ScanningView()
                    case .review(let category): ReviewView(category: category)
                    case .similar: SimilarView()
                    case .videos(let category): VideosView(category: category)
                    case .done(let result): DoneView(result: result) { path.removeAll() }
                    }
                }
        }
        .environment(\.sweep, SweepNavigator(open: { path.append($0) }, confirm: openConfirm))
        .overlay {
            if plan != nil {
                Color(hex: 0x0B0B0C, opacity: 0.38)
                    .ignoresSafeArea()
                    .onTapGesture(perform: closeConfirm)
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) {
            if let plan {
                ConfirmSheet(plan: plan, onClean: clean, onCancel: closeConfirm)
                    .id(plan.id)
                    .transition(.move(edge: .bottom))
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    /// The design starts with a scan. Run it once, when the app has access and no results yet.
    private func startFirstScan() {
        guard store.hasAccess, store.result == nil, !store.isScanning else { return }
        #if DEBUG
        if applyDebugStart() { return }
        #endif
        store.startScan()
        path = [.scanning]
    }

    private func openConfirm(_ plan: CleanPlan) {
        withAnimation(.spring(duration: 0.35)) { self.plan = plan }
    }

    private func closeConfirm() {
        withAnimation(.spring(duration: 0.35)) { plan = nil }
    }

    private func clean(_ result: CleanResult) {
        closeConfirm()
        path.append(.done(result))
    }

    #if DEBUG
    /// Opens a screen at launch, for screenshots: `-SweepStart home|review|similar|videos|confirm|done`.
    /// Returns false when the argument is not set.
    private func applyDebugStart() -> Bool {
        guard let start = UserDefaults.standard.string(forKey: "SweepStart") else { return false }
        Task {
            await store.scan()
            switch start {
            case "review": path = [.review(.screenshots)]
            case "similar": path = [.similar]
            case "videos": path = [.videos(.largeVideos)]
            case "confirm": if let result = store.result { openConfirm(.allSuggested(in: result)) }
            case "done": path = [.done(CleanResult(items: 12, bytes: 480_000_000))]
            default: break
            }
        }
        return true
    }
    #endif
}

/// Shown until the app has photo access.
private struct AccessView: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Palette.accent)
                .frame(width: 72, height: 72)
                .background(Palette.accentSoft, in: Circle())
            VStack(spacing: 6) {
                Text("Allow photo access")
                    .textStyle(.title)
                    .foregroundStyle(Palette.ink)
                Text("The app checks your photos on this device to find junk. Nothing is uploaded.")
                    .textStyle(.body)
                    .foregroundStyle(Palette.muted)
            }
            .multilineTextAlignment(.center)
            Spacer()
            if store.authorization == .notDetermined {
                PillButton(title: "Allow access") { Task { await store.requestAccess() } }
            } else {
                PillButton(title: "Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
    }
}

#Preview {
    SweepRootView()
        .environment(LibraryStore())
}
