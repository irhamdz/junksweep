import SwiftUI

/// On-device AI scan progress. Matches design/design/Scanning.dc.html.
struct ScanningView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private static let orbitScenes: [PhotoScene] = [.sunset, .shot, .beach, .night, .blossom, .forest, .concert, .city, .dark, .sunset2]
    private static let orbitSizes: [CGFloat] = [48, 40, 52, 38, 46, 42, 50, 36, 44, 40]

    private var phase: ScanProgress.Phase {
        store.scanProgress?.phase ?? (store.isScanning ? .photos : .finished)
    }

    private var found: ScanResult { store.scanProgress?.snapshot ?? store.result ?? ScanResult() }

    private var foundBytes: Int64 {
        JunkCategory.sweepOrder.flatMap { found.suggested(for: $0) }.totalBytes
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            orbit
                .padding(.top, 16)
            VStack(spacing: 8) {
                Label {
                    Text("On-device AI · nothing is uploaded")
                } icon: {
                    Image(systemName: "shield").font(.system(size: 12, weight: .semibold))
                }
                .labelStyle(TightLabelStyle(spacing: 5))
                .textStyle(.footnote)
                .foregroundStyle(Palette.muted)

                Text(phase == .finished ? "Your library is sorted" : "Finding the junk in your library")
                    .textStyle(.display)
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)

                if store.hasLimitedAccess {
                    limitedAccessNote
                }
            }
            .padding(.top, 14)

            rows
                .padding(.top, 20)

            Spacer(minLength: 16)

            PillButton(title: phase == .finished
                       ? "See \(foundBytes.sizeLabel) found"
                       : "See \(foundBytes.sizeLabel) found so far",
                       height: 54) { dismiss() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 34)
        .background(Palette.surface)
        .ignoresSafeArea(edges: .bottom)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            Color.clear.frame(width: 44, height: 44)
            Spacer()
            HStack(alignment: .top, spacing: 1) {
                Text("Sweep").font(.system(size: 17, weight: .bold)).tracking(-0.17)
                Text("AI").font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(Palette.ink)
            Spacer()
            Button {
                store.cancelScan()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 40, height: 40)
                    .background(Palette.background, in: Circle())
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Cancel scan")
        }
        .frame(height: 44)
        .padding(.horizontal, -2)
    }

    /// With limited access, PhotoKit returns only the photos the user shared, so the total is small.
    private var limitedAccessNote: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            (Text("Only the photos you shared are scanned. ")
                + Text("Allow full access").fontWeight(.semibold).foregroundColor(Palette.accent))
                .textStyle(.footnote)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Ten thumbnails on an ellipse around the progress ring.
    private var orbit: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Self.orbitScenes.indices, id: \.self) { i in
                let count = Double(Self.orbitScenes.count)
                let angle = Double(i) / count * 2 * .pi - .pi / 2
                let size = Self.orbitSizes[i]
                let tilt = Double(i % 2 == 1 ? 1 : -1) * Double(4 + (i % 3) * 3)
                ScenePhoto(scene: Self.orbitScenes[i])
                    .frame(width: size - 6, height: size - 6)
                    .photoFrame(cornerRadius: 14, border: 3)
                    .shadow(css: 0.14, blur: 16, y: 6)
                    .opacity(i == 8 ? 0.6 : 1)
                    .rotationEffect(.degrees(tilt))
                    .offset(x: (179 + 128 * cos(angle) - size / 2).rounded(),
                            y: (150 + 118 * sin(angle) - size / 2).rounded())
            }
            ProgressRing(progress: store.progress,
                         processed: store.scanProgress?.processed ?? 0,
                         total: store.scanProgress?.total ?? 0)
                .offset(x: 104, y: 75)
        }
        .frame(width: 358, height: 300, alignment: .topLeading)
    }

    private var rowData: [(name: String, count: String, done: Bool)] {
        let photosDone = phase != .photos
        func photoCount(_ category: JunkCategory) -> String {
            let count = found.suggested(for: category).count.formatted()
            return photosDone ? count : "\(count) so far"
        }
        let videoCount = JunkCategory.videoCategories.flatMap { found.suggested(for: $0) }.uniqued.count.formatted()
        return [
            ("Screenshots", photoCount(.screenshots), photosDone),
            ("Blurry photos", photoCount(.blurry), photosDone),
            ("Similar shots", photoCount(.similar), photosDone),
            ("Videos", phase == .photos ? "Queued" : phase == .videos ? "\(videoCount) so far" : videoCount,
             phase == .finished),
        ]
    }

    private var rows: some View {
        VStack(spacing: 0) {
            ForEach(rowData, id: \.name) { row in
                HStack(spacing: 10) {
                    if row.done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Palette.ink, in: Circle())
                            .accessibilityLabel("Done")
                    } else {
                        Spinner().accessibilityLabel("In progress")
                    }
                    Text(row.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text(row.count)
                        .textStyle(.callout)
                        .foregroundStyle(Palette.muted)
                }
                .frame(minHeight: 44)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Palette.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct ProgressRing: View {
    let progress: Double
    let processed: Int
    let total: Int

    var body: some View {
        ZStack {
            Circle().fill(Palette.surface)
            Circle().stroke(Color(hex: 0xEEF0F3), lineWidth: 8).padding(13)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Palette.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(13)
            VStack(spacing: 3) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(34 * -0.03)
                    .foregroundStyle(Palette.ink)
                Text("\(processed.formatted()) / \(total.formatted())")
                    .textStyle(.caption)
                    .foregroundStyle(Palette.muted)
            }
        }
        .frame(width: 150, height: 150)
        .shadow(css: 0.12, blur: 32, y: 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Scan progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

/// 20 pt ring with a turning accent arc.
private struct Spinner: View {
    @State private var turning = false

    var body: some View {
        ZStack {
            Circle().stroke(Palette.switchOff, lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(Palette.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(turning ? 315 : -45))
        }
        .padding(1.25)
        .frame(width: 20, height: 20)
        .onAppear {
            withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) { turning = true }
        }
    }
}

#Preview {
    NavigationStack { ScanningView() }
        .environment(LibraryStore())
}
