import SwiftUI
import UIKit

extension AppTheme {
    var backgroundPhotoName: String? {
        self == .muscle ? "theme-muscle" : nil
    }

    var photoOverlayOpacity: Double {
        self == .muscle ? 0.50 : 0
    }

    // These palettes stay dark so system controls and secondary text remain readable.
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .midnight, .slate, .afterHours, .cherry, .muscle: .dark
        default: nil
        }
    }

    var accentColor: Color {
        switch self {
        case .warm: adaptiveColor(light: 0xA8432D, dark: 0xFFB199)
        case .midnight: adaptiveColor(light: 0x80D6D0, dark: 0x80D6D0)
        case .playful: adaptiveColor(light: 0xAD285A, dark: 0xFFA6CC)
        case .refined: adaptiveColor(light: 0x315B48, dark: 0xB7CFAC)
        case .paper: adaptiveColor(light: 0x6B5949, dark: 0xD8C7B2)
        case .slate: adaptiveColor(light: 0xD4DEE9, dark: 0xD4DEE9)
        case .coast: adaptiveColor(light: 0x246675, dark: 0xA4DFE4)
        case .forest: adaptiveColor(light: 0x355C3E, dark: 0xB7D8AE)
        case .goldenHour: adaptiveColor(light: 0x8E4C20, dark: 0xFFD09A)
        case .afterHours: adaptiveColor(light: 0xF1B8D0, dark: 0xF1B8D0)
        case .cherry: adaptiveColor(light: 0xFFD4BC, dark: 0xFFD4BC)
        case .bubblegum: adaptiveColor(light: 0x8C2350, dark: 0xFFB9D5)
        case .daydream: adaptiveColor(light: 0x674192, dark: 0xD4B8FA)
        case .muscle: adaptiveColor(light: 0xBAC7D2, dark: 0xBAC7D2)
        }
    }

    var textColor: Color {
        switch self {
        case .warm: adaptiveColor(light: 0x35251F, dark: 0xFFF2E8)
        case .midnight: adaptiveColor(light: 0xEEF3FF, dark: 0xEEF3FF)
        case .playful: adaptiveColor(light: 0x54213F, dark: 0xFFF0F7)
        case .refined: adaptiveColor(light: 0x30362C, dark: 0xF4F1E6)
        case .paper: adaptiveColor(light: 0x33302C, dark: 0xF7F2E9)
        case .slate: adaptiveColor(light: 0xF4F6F8, dark: 0xF4F6F8)
        case .coast: adaptiveColor(light: 0x21434D, dark: 0xEDFAFB)
        case .forest: adaptiveColor(light: 0x293E2C, dark: 0xF2F6EA)
        case .goldenHour: adaptiveColor(light: 0x563522, dark: 0xFFF1D7)
        case .afterHours: adaptiveColor(light: 0xFFF0F6, dark: 0xFFF0F6)
        case .cherry: adaptiveColor(light: 0xFFF2DE, dark: 0xFFF2DE)
        case .bubblegum: adaptiveColor(light: 0x6F2146, dark: 0xFFF0F6)
        case .daydream: adaptiveColor(light: 0x493261, dark: 0xF6F0FF)
        case .muscle: adaptiveColor(light: 0xF5F5F2, dark: 0xF5F5F2)
        }
    }

    var backgroundGradient: LinearGradient {
        let colors: [Color]
        switch self {
        case .warm:
            colors = [adaptiveColor(light: 0xFFF5EB, dark: 0x291C19),
                      adaptiveColor(light: 0xF5D6C2, dark: 0x422920)]
        case .midnight:
            colors = [adaptiveColor(light: 0x101827, dark: 0x101827),
                      adaptiveColor(light: 0x292039, dark: 0x292039)]
        case .playful:
            colors = [adaptiveColor(light: 0xFFF1F5, dark: 0x2B192C),
                      adaptiveColor(light: 0xEEDDF6, dark: 0x41213C)]
        case .refined:
            colors = [adaptiveColor(light: 0xF6F3EA, dark: 0x20231E),
                      adaptiveColor(light: 0xE2DDCF, dark: 0x33382E)]
        case .paper:
            colors = [adaptiveColor(light: 0xF8F5EF, dark: 0x24221F),
                      adaptiveColor(light: 0xF0EBE3, dark: 0x2E2B27)]
        case .slate:
            colors = [adaptiveColor(light: 0x343940, dark: 0x23272D),
                      adaptiveColor(light: 0x252A31, dark: 0x171B21)]
        case .coast:
            colors = [adaptiveColor(light: 0xE8F5F4, dark: 0x142D36),
                      adaptiveColor(light: 0xC5E1E8, dark: 0x1C424A)]
        case .forest:
            colors = [adaptiveColor(light: 0xEEF2E8, dark: 0x1B3028),
                      adaptiveColor(light: 0xCCDCC8, dark: 0x2D4835)]
        case .goldenHour:
            colors = [adaptiveColor(light: 0xFFF0D3, dark: 0x392719),
                      adaptiveColor(light: 0xF4C5A4, dark: 0x583627)]
        case .afterHours:
            colors = [adaptiveColor(light: 0x382038, dark: 0x2B182D),
                      adaptiveColor(light: 0x17111C, dark: 0x100D15)]
        case .cherry:
            colors = [adaptiveColor(light: 0x941E3B, dark: 0x65152D),
                      adaptiveColor(light: 0x570F2B, dark: 0x350C20)]
        case .bubblegum:
            colors = [adaptiveColor(light: 0xFFD5E6, dark: 0x442033),
                      adaptiveColor(light: 0xFFDEC9, dark: 0x563026)]
        case .muscle:
            colors = [adaptiveColor(light: 0x252A30, dark: 0x252A30),
                      adaptiveColor(light: 0x0D1014, dark: 0x0D1014)]
        case .daydream:
            colors = [adaptiveColor(light: 0xEDE1FA, dark: 0x2C2342),
                      adaptiveColor(light: 0xD7EAF7, dark: 0x203749)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var fontDesign: Font.Design {
        switch self {
        case .warm, .midnight, .slate, .coast, .cherry, .muscle: .default
        case .playful, .bubblegum, .daydream: .rounded
        case .refined, .paper, .forest, .goldenHour, .afterHours: .serif
        }
    }

    var affirmationFont: Font {
        let weight: Font.Weight
        switch self {
        case .muscle: weight = .bold
        case .playful, .bubblegum, .daydream, .cherry: weight = .semibold
        default: weight = .regular
        }
        return .system(.largeTitle, design: fontDesign, weight: weight)
    }

    private func adaptiveColor(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .warm
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackground())
    }
}

private struct ThemedBackground: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(theme.backgroundGradient.ignoresSafeArea())
    }
}
