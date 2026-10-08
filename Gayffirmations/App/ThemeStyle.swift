import SwiftUI

extension AppTheme {
    var colorScheme: ColorScheme {
        switch self {
        case .nature: .light
        case .steel, .disco, .concrete: .dark
        }
    }

    var accentColor: Color {
        switch self {
        case .nature: Color(hex: 0x286B65)
        case .steel: Color(hex: 0xA7C9E0)
        case .disco: Color(hex: 0xFFB276)
        case .concrete: Color(hex: 0xC9C8BF)
        }
    }

    var textColor: Color {
        switch self {
        case .nature: Color(hex: 0x203D38)
        case .steel: Color(hex: 0xF0F4F7)
        case .disco: Color(hex: 0xFFF2FA)
        case .concrete: Color(hex: 0xF3F2ED)
        }
    }

    var backgroundGradient: LinearGradient {
        switch self {
        case .nature:
            LinearGradient(colors: [Color(hex: 0xF0F3E9), Color(hex: 0xC9E4DD)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .steel:
            LinearGradient(colors: [Color(hex: 0x202830), Color(hex: 0x354350)],
                           startPoint: .top, endPoint: .bottom)
        case .concrete:
            LinearGradient(colors: [Color(hex: 0x292B2A), Color(hex: 0x555650)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .disco:
            LinearGradient(colors: [Color(hex: 0x17285D), Color(hex: 0x532478), Color(hex: 0x872C68)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var fontDesign: Font.Design {
        switch self {
        case .nature, .steel, .concrete: .default
        case .disco: .rounded
        }
    }

    var affirmationWeight: Font.Weight {
        switch self {
        case .nature, .concrete: .regular
        case .steel: .bold
        case .disco: .semibold
        }
    }

    var affirmationLineSpacing: CGFloat {
        switch self {
        case .nature: 8
        case .steel: 4
        case .disco: 6
        case .concrete: 8
        }
    }

    var affirmationFont: Font {
        .system(.largeTitle, design: fontDesign, weight: affirmationWeight)
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: 1)
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .nature
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

extension View {
    func themeAppearance(_ theme: AppTheme) -> some View {
        environment(\.appTheme, theme)
            .environment(\.colorScheme, theme.colorScheme)
            .tint(theme.accentColor)
            .fontDesign(theme.fontDesign)
    }

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
