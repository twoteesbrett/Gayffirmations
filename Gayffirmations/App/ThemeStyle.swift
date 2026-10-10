import SwiftUI

extension AppTheme {
    var colorScheme: ColorScheme {
        switch self {
        case .eden, .steel, .disco, .concrete, .outAndAbout: .dark
        }
    }

    var accentColor: Color {
        switch self {
        case .eden: Color(hex: 0xC6E8AD)
        case .steel: Color(hex: 0xA7C9E0)
        case .disco: Color(hex: 0xFFB276)
        case .concrete: Color(hex: 0xC9C8BF)
        case .outAndAbout: Color(hex: 0xB9E2F5)
        }
    }

    var textColor: Color {
        switch self {
        case .eden: Color(hex: 0xF2F8ED)
        case .steel: Color(hex: 0xF0F4F7)
        case .disco: Color(hex: 0xFFF2FA)
        case .concrete: Color(hex: 0xF3F2ED)
        case .outAndAbout: Color(hex: 0xF0F7FC)
        }
    }

    var backgroundGradient: LinearGradient {
        switch self {
        case .eden:
            LinearGradient(colors: [Color(hex: 0x4C8240), Color(hex: 0x123D27)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .outAndAbout:
            LinearGradient(colors: [Color(hex: 0x327FA8), Color(hex: 0x123E5A)],
                           startPoint: .top, endPoint: .bottom)
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

    var interfaceFontDesign: Font.Design? {
        switch self {
        case .disco: .rounded
        case .eden, .steel, .concrete, .outAndAbout: nil
        }
    }

    var affirmationLineSpacing: CGFloat {
        switch self {
        case .eden, .outAndAbout: 8
        case .steel: 4
        case .disco: 6
        case .concrete: 8
        }
    }

    func affirmationFont(for role: AffirmationTextRole) -> Font {
        switch self {
        case .eden:
            .custom("Baskerville", size: role.baseSize, relativeTo: role.textStyle)
        case .steel:
            .system(role.textStyle, design: .default, weight: .bold)
        case .disco:
            .system(role.textStyle, design: .rounded, weight: .semibold)
        case .concrete, .outAndAbout:
            .system(role.textStyle, design: .default, weight: .regular)
        }
    }

}

enum AffirmationTextRole {
    case message, preview

    var textStyle: Font.TextStyle {
        switch self {
        case .message: .largeTitle
        case .preview: .title2
        }
    }

    var baseSize: CGFloat {
        switch self {
        case .message: 34
        case .preview: 22
        }
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
    static let defaultValue: AppTheme = .eden
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
            .fontDesign(theme.interfaceFontDesign)
    }

    func affirmationTypography(_ theme: AppTheme, role: AffirmationTextRole = .message) -> some View {
        // Affirmation typefaces own their design, independently of interface typography.
        font(theme.affirmationFont(for: role))
            .fontDesign(nil)
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
