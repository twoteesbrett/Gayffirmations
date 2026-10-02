import SwiftUI
import UIKit

extension AppTheme {
    var accentColor: Color { adaptiveColor(light: 0x4D5865, dark: 0xBBC5D0) }
    var textColor: Color { adaptiveColor(light: 0x292929, dark: 0xF3F3F3) }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [adaptiveColor(light: 0xF5F5F3, dark: 0x202123),
                     adaptiveColor(light: 0xE9E9E6, dark: 0x282A2D)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var fontDesign: Font.Design { .default }
    var affirmationFont: Font { .system(.largeTitle, design: fontDesign) }

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
    static let defaultValue: AppTheme = .neutral
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
