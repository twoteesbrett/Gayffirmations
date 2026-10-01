import SwiftUI
import UIKit

extension AppTheme {
    var backgroundPhotoName: String { "theme-\(rawValue)" }

    var accentColor: Color {
        switch self {
        case .warm: adaptiveColor(light: 0xA8432D, dark: 0xFFB199)
        case .midnight: adaptiveColor(light: 0x286B70, dark: 0x80D6D0)
        case .playful: adaptiveColor(light: 0xAD285A, dark: 0xFFA6CC)
        case .refined: adaptiveColor(light: 0x315B48, dark: 0xB7CFAC)
        }
    }

    var backgroundGradient: LinearGradient {
        let colors: [Color]
        switch self {
        case .warm:
            colors = [adaptiveColor(light: 0xFFF5EB, dark: 0x291C19),
                      adaptiveColor(light: 0xF5D6C2, dark: 0x422920)]
        case .midnight:
            colors = [adaptiveColor(light: 0xF0EFF8, dark: 0x101827),
                      adaptiveColor(light: 0xD7DFEC, dark: 0x292039)]
        case .playful:
            colors = [adaptiveColor(light: 0xFFF1F5, dark: 0x2B192C),
                      adaptiveColor(light: 0xEEDDF6, dark: 0x41213C)]
        case .refined:
            colors = [adaptiveColor(light: 0xF6F3EA, dark: 0x20231E),
                      adaptiveColor(light: 0xE2DDCF, dark: 0x33382E)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var fontDesign: Font.Design {
        switch self {
        case .warm, .midnight: .default
        case .playful: .rounded
        case .refined: .serif
        }
    }

    var affirmationFont: Font {
        .system(.largeTitle, design: fontDesign, weight: self == .playful ? .semibold : .regular)
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
