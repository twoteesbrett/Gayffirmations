import SwiftUI

extension AppTheme {
    var accentColor: Color {
        switch self {
        case .warm:
            Color(red: 0.88, green: 0.32, blue: 0.20)
        case .midnight:
            Color(red: 0.38, green: 0.84, blue: 0.82)
        case .playful:
            Color(red: 0.93, green: 0.12, blue: 0.46)
        case .refined:
            Color(red: 0.08, green: 0.25, blue: 0.20)
        }
    }

    var previewColors: [Color] {
        switch self {
        case .warm:
            [.orange, Color(red: 1, green: 0.72, blue: 0.56), .blue]
        case .midnight:
            [.purple, .pink, .cyan]
        case .playful:
            [.pink, .yellow, .mint]
        case .refined:
            [Color(red: 0.08, green: 0.25, blue: 0.20), .brown, .white]
        }
    }

    var backgroundGradient: LinearGradient {
        let colors: [Color]

        switch self {
        case .warm:
            colors = [
                Color(red: 1, green: 0.93, blue: 0.88),
                Color(red: 1, green: 0.78, blue: 0.66)
            ]
        case .midnight:
            colors = [
                Color(red: 0.05, green: 0.07, blue: 0.13),
                Color(red: 0.16, green: 0.09, blue: 0.24)
            ]
        case .playful:
            colors = [
                Color(red: 1, green: 0.88, blue: 0.92),
                Color(red: 0.95, green: 0.78, blue: 0.94)
            ]
        case .refined:
            colors = [
                Color(red: 0.95, green: 0.92, blue: 0.86),
                Color(red: 0.83, green: 0.80, blue: 0.71)
            ]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var preferredColorScheme: ColorScheme? {
        self == .midnight ? .dark : .light
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
