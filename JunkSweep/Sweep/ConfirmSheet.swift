import SwiftUI

/// Bulk clean of the groups in a plan. Floats over the current screen. Matches design/design/Confirm.dc.html.
struct ConfirmSheet: View {
    let plan: CleanPlan
    let onClean: (CleanResult) -> Void
    let onCancel: () -> Void

    @Environment(LibraryStore.self) private var store
    @State private var excluded = Set<JunkCategory>()
    @State private var isDeleting = false
    @State private var dragOffset: CGFloat = 0

    private var items: [JunkItem] {
        plan.groups.filter { !excluded.contains($0.category) }.flatMap(\.items)
    }

    var body: some View {
        let items = items
        let bytes = items.totalBytes
        VStack(spacing: 12) {
            Capsule()
                .fill(Palette.disabled)
                .frame(width: 40, height: 5)

            VStack(spacing: 4) {
                Text("Clean \(items.count.itemsLabel)?")
                    .textStyle(.sheetTitle)
                    .foregroundStyle(Palette.ink)
                Text("Only AI suggestions. Anything marked “keep” stays.")
                    .textStyle(.callout)
                    .foregroundStyle(Palette.muted)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: 0) {
                ForEach(plan.groups) { group in
                    Toggle(isOn: binding(for: group.category)) {
                        GroupRow(group: group)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 2)
            .background(Palette.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            Label {
                Text("Restorable from Recently Deleted for 30 days")
            } icon: {
                Image(systemName: "shield")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.accent)
            }
            .labelStyle(TightLabelStyle(spacing: 8))
            .textStyle(.footnote)
            .foregroundStyle(Palette.inkSoft)

            if items.isEmpty {
                PillButton(title: "Pick at least one group", kind: .disabled) {}
            } else {
                PillButton(title: "Clean \(items.count.itemsLabel) · \(bytes.sizeLabel)",
                           systemImage: "trash", kind: isDeleting ? .disabled : .destructive) {
                    clean(items, bytes: bytes)
                }
            }

            Button(action: onCancel) {
                Text("Cancel")
                    .textStyle(.button)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isDeleting)
        }
        .padding(.top, 10)
        .padding(.horizontal, 18)
        .padding(.bottom, 22)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
        .padding(8)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { dragOffset = max(0, $0.translation.height) }
                .onEnded { value in
                    if value.translation.height > 120 && !isDeleting {
                        onCancel()
                    } else {
                        withAnimation(.spring(duration: 0.3)) { dragOffset = 0 }
                    }
                }
        )
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onCancel)
    }

    /// iOS then asks the user to confirm the delete once more. If they cancel there, the sheet stays open.
    private func clean(_ items: [JunkItem], bytes: Int64) {
        isDeleting = true
        Task {
            if await store.delete(items) {
                onClean(CleanResult(items: items.count, bytes: bytes))
            }
            isDeleting = false
        }
    }

    private func binding(for category: JunkCategory) -> Binding<Bool> {
        Binding(
            get: { !excluded.contains(category) },
            set: { if $0 { excluded.remove(category) } else { excluded.insert(category) } }
        )
    }
}

private struct GroupRow: View {
    let group: CleanPlan.Group

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(group.category.tint)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.white, lineWidth: 2))
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 0) {
                Text(group.category.sweepTitle)
                    .textStyle(.bodyStrong)
                    .foregroundStyle(Palette.ink)
                Text([group.items.count.itemsLabel, group.category.confirmNote].compactMap { $0 }.joined(separator: " · "))
                    .textStyle(.caption)
                    .foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 0)
            Text(group.items.totalBytes.sizeLabel)
                .textStyle(.calloutStrong)
                .foregroundStyle(Palette.ink)
        }
    }
}

/// 22 pt checkbox after the label. The whole row is the touch target.
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 12) {
                configuration.label
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(configuration.isOn ? Palette.accent : Palette.surface)
                    .overlay {
                        if configuration.isOn {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundStyle(.white)
                        } else {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Palette.muted.opacity(0.6), lineWidth: 1.5)
                        }
                    }
                    .frame(width: 22, height: 22)
            }
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
        .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color.black.opacity(0.38).ignoresSafeArea()
        ConfirmSheet(plan: CleanPlan([]), onClean: { _ in }, onCancel: {})
    }
    .ignoresSafeArea(edges: .bottom)
    .environment(LibraryStore())
}
