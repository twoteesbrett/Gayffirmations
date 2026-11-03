import SwiftUI

struct ThemeImage: Identifiable {
    let id: String
    let name: String
    let focalPoint: UnitPoint
    let overlayOpacity: Double
    let accessibilityDescription: String

    let textColor: Color
}

extension AppTheme {
    var images: [ThemeImage] {
        switch self {
        case .steel:
            return [
                ThemeImage(id: "steel-strength", name: "Strength", focalPoint: UnitPoint(x: 0.85, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated monochrome portrait of a standing man curling a barbell", textColor: .white),
                ThemeImage(id: "steel-release", name: "Release", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated monochrome portrait of a man lifting a kettlebell with his head tilted back", textColor: .white),
                ThemeImage(id: "steel-curl", name: "Curl", focalPoint: UnitPoint(x: 0.70, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "A monochrome portrait of a seated man curling a dumbbell", textColor: .white),
                ThemeImage(id: "steel-deadlift", name: "Deadlift", focalPoint: UnitPoint(x: 0.52, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "A monochrome portrait of a man preparing to deadlift a barbell", textColor: .white),
                ThemeImage(id: "steel-squat", name: "Squat", focalPoint: UnitPoint(x: 0.55, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated monochrome portrait of a man squatting with a barbell", textColor: .white),
                ThemeImage(id: "steel-pull-up", name: "Pull-up", focalPoint: .center,
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated monochrome portrait of a man doing a pull-up, viewed from behind", textColor: .white)
            ]
        case .outAndAbout:
            return [
                ThemeImage(id: "out-and-about-lakeside", name: "Lakeside", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of people relaxing beside lakeside cabins, swimming and paddling on an alpine lake at golden dawn", textColor: .white),
                ThemeImage(id: "out-and-about-alpine-cafe", name: "Alpine Café", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of people relaxing at a flower-lined alpine café beside a mountain stream", textColor: .white),
                ThemeImage(id: "out-and-about-market", name: "Market", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of people strolling through a colourful Mediterranean market beside a sunny bay", textColor: .white),
                ThemeImage(id: "out-and-about-park", name: "Park", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of people picnicking and cycling in a flower-filled park beside a lake", textColor: .white),
                ThemeImage(id: "out-and-about-pool-club", name: "Pool Club", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of people swimming and relaxing beside a tropical pool overlooking mountains", textColor: .white),
                ThemeImage(id: "out-and-about-beach", name: "Beach", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of people relaxing, swimming and playing volleyball at a sunny beach beside a rocky headland", textColor: .white),
                ThemeImage(id: "out-and-about-waterfall", name: "Waterfall", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of people relaxing beside a woodland waterfall and turquoise swimming hole", textColor: .white),
                ThemeImage(id: "out-and-about-harbour", name: "Harbour", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of people dining and walking along a flower-lined harbour promenade at golden hour", textColor: .white),
                ThemeImage(id: "out-and-about-moonlit-lakeside", name: "Moonlit Lakeside", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of people gathered around a campfire beside an alpine lake under the moon", textColor: .white)
            ]
        }
    }
}

private struct ThemeImageKey: EnvironmentKey {
    static let defaultValue: ThemeImage? = nil
}

extension EnvironmentValues {
    var themeImage: ThemeImage? {
        get { self[ThemeImageKey.self] }
        set { self[ThemeImageKey.self] = newValue }
    }
}
