import SwiftUI

// MARK: - Buttons

/// 40 pt round button with a stroke icon. Used in screen headers.
struct RoundIconButton: View {
    let systemImage: String
    let label: String
    var iconSize: CGFloat = 18
    var iconWeight: Font.Weight = .semibold
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: iconWeight))
                .foregroundStyle(Palette.ink)
                .frame(width: 40, height: 40)
                .background(Palette.surface, in: Circle())
                .elevation(.button)
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(label)
    }
}

enum PillKind {
    case primary, accent, destructive, disabled

    var background: Color {
        switch self {
        case .primary: Palette.ink
        case .accent: Palette.accent
        case .destructive: Palette.destructive
        case .disabled: Palette.disabled
        }
    }

    var foreground: Color { self == .disabled ? Palette.muted : .white }
}

/// Fully rounded button. Height sets the corner radius (height / 2).
struct PillButton: View {
    let title: String
    var systemImage: String?
    var kind: PillKind = .primary
    var height: CGFloat = 56
    var horizontalPadding: CGFloat = 0
    var fillsWidth = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 17, weight: .semibold))
                }
                Text(title).textStyle(.button)
            }
            .foregroundStyle(kind.foreground)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .padding(.horizontal, horizontalPadding)
            .frame(height: height)
            .background(kind.background, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(kind == .disabled)
    }
}

/// 38 pt filter chip. Selected chips are black.
struct FilterChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .textStyle(isSelected ? .calloutStrong : .calloutMedium)
            .foregroundStyle(isSelected ? .white : Palette.ink)
            .padding(.horizontal, 16)
            .frame(height: 38)
            .background(isSelected ? Palette.ink : Palette.surface, in: Capsule())
            .overlay {
                if !isSelected { Capsule().strokeBorder(Palette.line, lineWidth: 1) }
            }
            .fixedSize()
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Small label on a photo, e.g. "OTP code" or "AI: keep".
struct PhotoTag: View {
    let text: String
    var dark = false
    var style: TextStyle = .tag
    var padding = EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)

    var body: some View {
        Text(text)
            .textStyle(style)
            .foregroundStyle(dark ? .white : Palette.ink)
            .padding(padding)
            .background(dark ? Palette.ink : Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 10))
    }
}

/// Round white button with an arrow, on category cards.
struct CardArrow: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(Palette.ink)
            .frame(width: size, height: size)
            .background(Palette.surface, in: Circle())
            .shadow(css: 0.12, blur: size > 40 ? 12 : 10, y: size > 40 ? 4 : 3)
    }
}

/// Translucent white strip with background blur on category cards.
struct FrostedStrip: View {
    let cornerRadius: CGFloat
    var tint: Double = 0.22

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(.ultraThinMaterial)
            .overlay(shape.fill(Color.white.opacity(tint)))
            .overlay(shape.strokeBorder(Color.white.opacity(0.45), lineWidth: 1))
    }
}

// MARK: - Photo placeholders

/// Colours for a placeholder photo: sky, sun and ground.
struct PhotoScene: Hashable {
    let sky: Color
    let sun: Color
    let ground: Color

    static let sunset = PhotoScene(sky: Color(hex: 0xF2A97F), sun: Color(hex: 0xFCE3B8), ground: Color(hex: 0x3E6F7C))
    static let sunset2 = PhotoScene(sky: Color(hex: 0xEE9C7A), sun: Color(hex: 0xFBE0B0), ground: Color(hex: 0x35636F))
    static let blossom = PhotoScene(sky: Color(hex: 0xF4C6CF), sun: Color(hex: 0xE77E95), ground: Color(hex: 0x6E8B5A))
    static let night = PhotoScene(sky: Color(hex: 0x1F2B4A), sun: Color(hex: 0xE9E4C9), ground: Color(hex: 0x0F1628))
    static let forest = PhotoScene(sky: Color(hex: 0xA9C9B4), sun: Color(hex: 0xF5F0D8), ground: Color(hex: 0x3F6B4E))
    static let beach = PhotoScene(sky: Color(hex: 0x9FD0E8), sun: Color(hex: 0xFFF1C2), ground: Color(hex: 0xE8D3A8))
    static let city = PhotoScene(sky: Color(hex: 0xC9D3E0), sun: Color(hex: 0xFFFFFF), ground: Color(hex: 0x56657A))
    static let dark = PhotoScene(sky: Color(hex: 0x2A2C30), sun: Color(hex: 0x3A3D42), ground: Color(hex: 0x1C1D20))
    static let concert = PhotoScene(sky: Color(hex: 0x3B2F6B), sun: Color(hex: 0xF06BA8), ground: Color(hex: 0x17122E))
    static let shot = PhotoScene(sky: Color(hex: 0xFFFFFF), sun: Color(hex: 0x1A5DD8), ground: Color(hex: 0xE9EDF5))
}

/// Flat landscape: a sun circle over a ground band. Positions are fractions of the frame.
struct ScenePhoto: View {
    let scene: PhotoScene
    var sunX: CGFloat = 0.52
    var sunY: CGFloat = 0.14
    var sunWidth: CGFloat = 0.32
    var groundHeight: CGFloat = 0.36
    var blur: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack(alignment: .topLeading) {
                scene.sky
                Circle()
                    .fill(scene.sun)
                    .frame(width: w * sunWidth, height: w * sunWidth)
                    .offset(x: w * sunX, y: h * sunY)
                scene.ground
                    .frame(height: h * groundHeight)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .blur(radius: blur)
        }
    }
}

extension View {
    /// White border drawn inside the frame, like CSS `box-sizing: border-box`.
    func photoFrame(cornerRadius: CGFloat, border: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: cornerRadius - border, style: .continuous))
            .padding(border)
            .background(Color.white, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
