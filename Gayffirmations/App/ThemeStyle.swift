import SwiftUI

extension AppTheme {
    var colorScheme: ColorScheme {
        switch self {
        case .steel, .outAndAbout, .together, .ages: .dark
        }
    }

    var accentColor: Color {
        switch self {
        case .ages: Color(hex: 0xEBC992)
        case .together: Color(hex: 0xF3CC9E)
        case .steel: Color(hex: 0xA7C9E0)
        case .outAndAbout: Color(hex: 0xB9E2F5)
        }
    }

    var textColor: Color {
        switch self {
        case .ages: Color(hex: 0xFFF6E8)
        case .together: Color(hex: 0xFFF5E9)
        case .steel: Color(hex: 0xF0F4F7)
        case .outAndAbout: Color(hex: 0xF0F7FC)
        }
    }

    var backgroundGradient: LinearGradient {
        switch self {
        case .ages:
            LinearGradient(colors: [Color(hex: 0x6B5940), Color(hex: 0x302A24)],
                           startPoint: .top, endPoint: .bottom)
        case .together:
            LinearGradient(colors: [Color(hex: 0x80553C), Color(hex: 0x392A29)],
                           startPoint: .top, endPoint: .bottom)
        case .outAndAbout:
            LinearGradient(colors: [Color(hex: 0x327FA8), Color(hex: 0x123E5A)],
                           startPoint: .top, endPoint: .bottom)
        case .steel:
            LinearGradient(colors: [Color(hex: 0x202830), Color(hex: 0x354350)],
                           startPoint: .top, endPoint: .bottom)
        }
    }

    var interfaceFontDesign: Font.Design? {
        switch self {
        case .steel, .outAndAbout, .together, .ages: nil
        }
    }

    var affirmationLineSpacing: CGFloat {
        switch self {
        case .outAndAbout, .together, .ages: 8
        case .steel: 4
        }
    }

    func affirmationFont(for role: AffirmationTextRole) -> Font {
        switch self {
        case .steel:
            .system(role.textStyle, design: .default, weight: .bold)
        case .outAndAbout, .together, .ages:
            .system(role.textStyle, design: .default, weight: .regular)
        }
    }

}

enum AffirmationTextRole {
    case message, preview, context

    var textStyle: Font.TextStyle {
        switch self {
        case .message: .largeTitle
        case .preview: .title2
        case .context: .body
        }
    }

    var baseSize: CGFloat {
        switch self {
        case .message: 34
        case .preview: 22
        case .context: 17
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
    static let defaultValue: AppTheme = .outAndAbout
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
