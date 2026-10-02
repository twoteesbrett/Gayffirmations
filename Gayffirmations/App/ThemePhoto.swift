import SwiftUI

struct ThemePhoto: Identifiable {
    let id: String
    let name: String
    let focalPoint: UnitPoint
    let overlayOpacity: Double
    let accessibilityDescription: String

    let textColor: Color
}

extension AppTheme {
    var photos: [ThemePhoto] {
        guard self == .steel else { return [] }
        return [
            ThemePhoto(id: "steel-strength", name: "Strength", focalPoint: UnitPoint(x: 0.58, y: 0.5),
                       overlayOpacity: 0.38, accessibilityDescription: "A man lifting a barbell in a dark gym", textColor: .white),
            ThemePhoto(id: "steel-presence", name: "Presence", focalPoint: .center,
                       overlayOpacity: 0.42, accessibilityDescription: "A close portrait of a shirtless man in a gym", textColor: .white),
            ThemePhoto(id: "steel-release", name: "Release", focalPoint: .center,
                       overlayOpacity: 0.48, accessibilityDescription: "A monochrome portrait of a man with his head tilted back", textColor: .white),
            ThemePhoto(id: "steel-water", name: "Water", focalPoint: .center,
                       overlayOpacity: 0.42, accessibilityDescription: "A man standing beneath falling water", textColor: .white)
        ]
    }
}

private struct ThemePhotoKey: EnvironmentKey {
    static let defaultValue: ThemePhoto? = nil
}

extension EnvironmentValues {
    var themePhoto: ThemePhoto? {
        get { self[ThemePhotoKey.self] }
        set { self[ThemePhotoKey.self] = newValue }
    }
}
