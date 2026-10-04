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
        switch self {
        case .nature:
            return [
                ThemePhoto(id: "nature-canyon", name: "Canyon", focalPoint: UnitPoint(x: 0.55, y: 0.5),
                           overlayOpacity: 0.42, accessibilityDescription: "Red sandstone canyon walls framing a ribbon of blue sky", textColor: .white),
                ThemePhoto(id: "nature-meadow", name: "Meadow", focalPoint: .center,
                           overlayOpacity: 0.38, accessibilityDescription: "Soft green meadow grasses against a shaded woodland background", textColor: .white),
                ThemePhoto(id: "nature-forest", name: "Forest", focalPoint: UnitPoint(x: 0.56, y: 0.5),
                           overlayOpacity: 0.48, accessibilityDescription: "Sunlight filtering through a green forest", textColor: .white),
                ThemePhoto(id: "nature-beach", name: "Beach", focalPoint: UnitPoint(x: 0.5, y: 0.60),
                           overlayOpacity: 0.50, accessibilityDescription: "Gentle waves washing over golden sand in warm evening light", textColor: .white),
                ThemePhoto(id: "nature-river", name: "River", focalPoint: UnitPoint(x: 0.5, y: 0.65),
                           overlayOpacity: 0.48, accessibilityDescription: "Clear blue river flowing around boulders beneath leafy trees", textColor: .white),
                ThemePhoto(id: "nature-waterfall", name: "Waterfall", focalPoint: UnitPoint(x: 0.45, y: 0.5),
                           overlayOpacity: 0.48, accessibilityDescription: "A cascading waterfall surrounded by lush green ferns and foliage", textColor: .white)
            ]
        case .steel:
            return [
                ThemePhoto(id: "steel-strength", name: "Strength", focalPoint: UnitPoint(x: 0.85, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated monochrome portrait of a standing man curling a barbell", textColor: .white),
                ThemePhoto(id: "steel-release", name: "Release", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated monochrome portrait of a man lifting a kettlebell with his head tilted back", textColor: .white),
                ThemePhoto(id: "steel-curl", name: "Curl", focalPoint: UnitPoint(x: 0.70, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "A monochrome portrait of a seated man curling a dumbbell", textColor: .white),
                ThemePhoto(id: "steel-deadlift", name: "Deadlift", focalPoint: UnitPoint(x: 0.52, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "A monochrome portrait of a man preparing to deadlift a barbell", textColor: .white),
                ThemePhoto(id: "steel-squat", name: "Squat", focalPoint: UnitPoint(x: 0.55, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated monochrome portrait of a man squatting with a barbell", textColor: .white),
                ThemePhoto(id: "steel-pull-up", name: "Pull-up", focalPoint: .center,
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated monochrome portrait of a man doing a pull-up, viewed from behind", textColor: .white)
            ]
        case .disco:
            return [
                ThemePhoto(id: "disco-aviators", name: "Aviators", focalPoint: .center,
                           overlayOpacity: 0.38, accessibilityDescription: "Aviator sunglasses on marble reflecting a mirrorball and pink and blue disco lights", textColor: .white),
                ThemePhoto(id: "disco-portrait", name: "Neon Portrait", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A shirtless man lit by pink and blue neon against vibrant bokeh", textColor: .white),
                ThemePhoto(id: "disco-mirrorball", name: "Mirrorball", focalPoint: UnitPoint(x: 0.60, y: 0.5),
                           overlayOpacity: 0.50, accessibilityDescription: "A mirrorball glowing under pink and blue disco spotlights", textColor: .white)
            ]
        case .refined:
            return []
        }
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
