import SwiftUI

// Design tokens from design/HANDOFF.md. Keep every colour, type size and shadow here.

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum Palette {
    static let background = Color(hex: 0xF2F3F5)
    static let surface = Color(hex: 0xFFFFFF)
    static let ink = Color(hex: 0x0B0B0C)
    static let muted = Color(hex: 0x5F646C)
    static let line = Color(hex: 0xE1E4E8)
    static let accent = Color(hex: 0x1A5DD8)
    static let accentSoft = Color(hex: 0xEAF0FC)
    static let destructive = Color(hex: 0xC8261B)

    /// Body copy inside cards and notes.
    static let inkSoft = Color(hex: 0x2C3036)
    /// Disabled buttons, placeholder bars and the profile button.
    static let disabled = Color(hex: 0xDDE0E6)
    /// Switch track when off.
    static let switchOff = Color(hex: 0xD5D9E0)
    /// Unread badge on the tab bar.
    static let badge = Color(hex: 0xE5484D)
    /// Base colour of every shadow: rgba(16,24,40).
    static let shadow = Color(hex: 0x101828)

    enum Tint {
        static let screenshots = Color(hex: 0xC7CCF6)
        static let similar = Color(hex: 0xF6B3B0)
        static let duplicates = Color(hex: 0xBFE3D3)
        static let blurry = Color(hex: 0xD9DBE1)
        static let largeVideos = Color(hex: 0xF3DDA0)
        static let accidental = Color(hex: 0xF5C6A5)
        static let screenRecordings = Color(hex: 0xDCC8F0)
    }
}

// MARK: - Type

/// System font (SF Pro). Tracking is in em, as in the design files.
struct TextStyle {
    let size: CGFloat
    let weight: Font.Weight
    var tracking: CGFloat = 0

    static let display = TextStyle(size: 32, weight: .semibold, tracking: -0.03)
    static let largeTitle = TextStyle(size: 30, weight: .semibold, tracking: -0.03)
    static let title = TextStyle(size: 28, weight: .semibold, tracking: -0.02)
    static let sheetTitle = TextStyle(size: 24, weight: .semibold, tracking: -0.02)
    static let section = TextStyle(size: 21, weight: .semibold, tracking: -0.01)
    static let navTitle = TextStyle(size: 17, weight: .semibold)
    static let button = TextStyle(size: 16, weight: .semibold)
    static let cardTitle = TextStyle(size: 16, weight: .semibold)
    static let body = TextStyle(size: 15, weight: .regular)
    static let bodyStrong = TextStyle(size: 15, weight: .semibold)
    static let callout = TextStyle(size: 14, weight: .regular)
    static let calloutStrong = TextStyle(size: 14, weight: .semibold)
    static let calloutMedium = TextStyle(size: 14, weight: .medium)
    static let footnote = TextStyle(size: 13, weight: .regular)
    static let footnoteStrong = TextStyle(size: 13, weight: .semibold)
    static let caption = TextStyle(size: 12, weight: .regular)
    static let tag = TextStyle(size: 11, weight: .semibold)
}

extension View {
    func textStyle(_ style: TextStyle) -> some View {
        font(.system(size: style.size, weight: style.weight))
            .tracking(style.size * style.tracking)
    }
}

// MARK: - Shadows

enum Elevation {
    /// 0 2px 8px, alpha 0.06. Round icon buttons.
    case button
    /// 0 2px 10px, alpha 0.04. Cards in a list.
    case card
    /// 0 8px 24px, alpha 0.12. Tab bar and white floating buttons.
    case floating
    /// 0 8px 24px, alpha 0.2. Black floating buttons.
    case floatingStrong

    fileprivate var values: (opacity: Double, radius: CGFloat, y: CGFloat) {
        // CSS blur is about twice the SwiftUI radius.
        switch self {
        case .button: (0.06, 4, 2)
        case .card: (0.04, 5, 2)
        case .floating: (0.12, 12, 8)
        case .floatingStrong: (0.2, 12, 8)
        }
    }
}

extension View {
    func elevation(_ level: Elevation) -> some View {
        let v = level.values
        return shadow(color: Palette.shadow.opacity(v.opacity), radius: v.radius, y: v.y)
    }

    func shadow(css opacity: Double, blur: CGFloat, y: CGFloat) -> some View {
        shadow(color: Palette.shadow.opacity(opacity), radius: blur / 2, y: y)
    }
}
