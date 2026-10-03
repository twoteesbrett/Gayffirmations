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
                ThemePhoto(id: "nature-night-sky", name: "Night sky", focalPoint: .center,
                           overlayOpacity: 0.12, accessibilityDescription: "Stars above silhouetted forest trees", textColor: .white),
                ThemePhoto(id: "nature-forest", name: "Forest", focalPoint: UnitPoint(x: 0.56, y: 0.5),
                           overlayOpacity: 0.48, accessibilityDescription: "Sunlight filtering through a green forest", textColor: .white),
                ThemePhoto(id: "nature-coast", name: "Coast", focalPoint: .center,
                           overlayOpacity: 0.50, accessibilityDescription: "Green coastal cliffs beside blue water and white surf", textColor: .white)
            ]
        case .steel:
            return [
                ThemePhoto(id: "steel-strength", name: "Strength", focalPoint: UnitPoint(x: 0.80, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated monochrome portrait of a man lifting a barbell", textColor: .white),
                ThemePhoto(id: "steel-release", name: "Release", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated monochrome portrait of a man lifting a kettlebell with his head tilted back", textColor: .white)
            ]
        case .together:
            return [
                ThemePhoto(id: "together-park", name: "Park", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated portrait of a happy couple cuddling in a park at golden hour", textColor: .white),
                ThemePhoto(id: "together-home", name: "Home", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated portrait of a happy couple laughing together on a sofa", textColor: .white),
                ThemePhoto(id: "together-city", name: "City", focalPoint: .center,
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated portrait of a happy couple walking arm in arm on a city street at night", textColor: .white),
                ThemePhoto(id: "together-coast", name: "Coast", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated portrait of a happy couple embracing beside the sea at sunset", textColor: .white)
            ]
        case .fruity:
            return [
                ThemePhoto(id: "fruity-cherry", name: "Cherry", focalPoint: .center,
                           overlayOpacity: 0.40, accessibilityDescription: "A winking kawaii cherry against a dreamy pastel background", textColor: .white),
                ThemePhoto(id: "fruity-aubergine", name: "Aubergine", focalPoint: .center,
                           overlayOpacity: 0.40, accessibilityDescription: "A winking kawaii aubergine against a dreamy pastel background", textColor: .white),
                ThemePhoto(id: "fruity-banana", name: "Banana", focalPoint: .center,
                           overlayOpacity: 0.40, accessibilityDescription: "A winking kawaii banana against a dreamy pastel background", textColor: .white),
                ThemePhoto(id: "fruity-peach", name: "Peach", focalPoint: .center,
                           overlayOpacity: 0.40, accessibilityDescription: "A winking kawaii peach against a dreamy pastel background", textColor: .white),
                ThemePhoto(id: "fruity-coconut", name: "Coconut", focalPoint: .center,
                           overlayOpacity: 0.40, accessibilityDescription: "A winking kawaii coconut against a dreamy pastel background", textColor: .white)
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
