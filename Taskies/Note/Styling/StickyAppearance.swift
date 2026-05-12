import SwiftUI

struct StickyPalette {
    let paperTop: Color
    let paperBottom: Color
    let titleTop: Color
    let titleBottom: Color
    let border: Color
    let text: Color
    let secondaryText: Color
}

enum StickyMetrics {
    static let headerHeight: CGFloat = CGFloat(StickyNote.collapsedHeight)
    static let defaultWindowSize = CGSize(width: 280, height: 236)
    static let minWindowSize = CGSize(width: 210, height: 122)
    static let minCollapsedWidth: CGFloat = 180
    static let rowHPadding: CGFloat = 11
    static let rowVPadding: CGFloat = 3.5
    static let rowMinHeight: CGFloat = 27
    static let rowHighlightInset: CGFloat = 5
    static let rowGlyphSize: CGFloat = 18
    static let rowGlyphSpacing: CGFloat = 8
    static let checkboxSize: CGFloat = 15
    static let taskFontSize: CGFloat = 13
}

extension StickyColor {
    var palette: StickyPalette {
        switch self {
        case .yellow:
            return StickyPalettes.yellow
        case .blue:
            return StickyPalettes.blue
        case .green:
            return StickyPalettes.green
        case .pink:
            return StickyPalettes.pink
        case .purple:
            return StickyPalettes.purple
        case .gray:
            return StickyPalettes.gray
        }
    }

    var accentColor: Color { palette.border }
    var textColor: Color { palette.text }
}

private enum StickyPalettes {
    static let yellow = StickyPalette(
        paperTop: Color(hex: 0xFFF7A7),
        paperBottom: Color(hex: 0xFFF19A),
        titleTop: Color(hex: 0xF3D56F),
        titleBottom: Color(hex: 0xE4C153),
        border: Color(hex: 0x8C7A38),
        text: Color(hex: 0x211C0C),
        secondaryText: Color(hex: 0x574B24)
    )

    static let blue = StickyPalette(
        paperTop: Color(hex: 0xBAC9FB),
        paperBottom: Color(hex: 0xBAC9FB),
        titleTop: Color(hex: 0xA0B5F8),
        titleBottom: Color(hex: 0xA0B5F8),
        border: Color(hex: 0x839AE5),
        text: Color(hex: 0x111827),
        secondaryText: Color(hex: 0x34415F)
    )

    static let green = StickyPalette(
        paperTop: Color(hex: 0xC3D9A2),
        paperBottom: Color(hex: 0xB9D292),
        titleTop: Color(hex: 0x9BC675),
        titleBottom: Color(hex: 0x88B861),
        border: Color(hex: 0x5B7E42),
        text: Color(hex: 0x12220D),
        secondaryText: Color(hex: 0x35522B)
    )

    static let pink = StickyPalette(
        paperTop: Color(hex: 0xF5B8CA),
        paperBottom: Color(hex: 0xEFAEC1),
        titleTop: Color(hex: 0xDE86A0),
        titleBottom: Color(hex: 0xCF7893),
        border: Color(hex: 0x8D5264),
        text: Color(hex: 0x2E1018),
        secondaryText: Color(hex: 0x653140)
    )

    static let purple = StickyPalette(
        paperTop: Color(hex: 0xCCB9E8),
        paperBottom: Color(hex: 0xC2ADDF),
        titleTop: Color(hex: 0xA48BD1),
        titleBottom: Color(hex: 0x967CC5),
        border: Color(hex: 0x6A5794),
        text: Color(hex: 0x20143A),
        secondaryText: Color(hex: 0x4E3A73)
    )

    static let gray = StickyPalette(
        paperTop: Color(hex: 0xD9D9D9),
        paperBottom: Color(hex: 0xD2D2D2),
        titleTop: Color(hex: 0xB7B7B7),
        titleBottom: Color(hex: 0xA7A7A7),
        border: Color(hex: 0x6A6A6A),
        text: Color(hex: 0x1E1E1E),
        secondaryText: Color(hex: 0x555555)
    )
}

struct StickyPaperBackground: View {
    let color: StickyColor

    var body: some View {
        color.palette.paperTop
    }
}

struct StickyNoteBodyBackground: View {
    let color: StickyColor

    var body: some View {
        ZStack {
            color.palette.paperTop

            VStack(spacing: 0) {
                Color.black.opacity(0.07)
                    .frame(height: 1)

                Color.white.opacity(0.16)
                    .frame(height: 1)

                Spacer(minLength: 0)

                Color.black.opacity(0.035)
                    .frame(height: 1)
            }

            HStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.black.opacity(0.045), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 5)

                Spacer(minLength: 0)

                LinearGradient(
                    colors: [Color.clear, Color.white.opacity(0.055)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 7)
            }
        }
    }
}

struct StickyTitleBarBackground: View {
    let color: StickyColor
    let isActive: Bool

    var body: some View {
        isActive ? color.palette.titleTop : color.palette.paperTop
    }
}

struct StickyTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
