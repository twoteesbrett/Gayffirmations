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
        case .eden:
            return [
                ThemeImage(id: "eden-monstera", name: "Monstera", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A dew-covered monstera leaf glowing in tropical sunlight", textColor: .white),
                ThemeImage(id: "eden-peace-lily", name: "Peace Lily", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A white peace lily covered in dew amid lush rainforest foliage", textColor: .white),
                ThemeImage(id: "eden-stream", name: "Stream", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Sunlight sparkling on a jungle stream flowing over moss-covered rocks", textColor: .white),
                ThemeImage(id: "eden-ferns", name: "Ferns", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Rain-kissed ferns arching over mossy rocks beside a forest stream", textColor: .white),
                ThemeImage(id: "eden-ivy", name: "Ivy", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Dew-covered ivy trailing over a mossy tree in jungle sunlight", textColor: .white),
                ThemeImage(id: "eden-tropical-leaves", name: "Tropical Leaves", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Sunlight shining through rain-covered tropical leaves", textColor: .white)
            ]
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
        case .disco:
            return [
                ThemeImage(id: "disco-aviators", name: "Aviators", focalPoint: .center,
                           overlayOpacity: 0.38, accessibilityDescription: "Aviator sunglasses on marble reflecting a mirrorball and pink and blue disco lights", textColor: .white),
                ThemeImage(id: "disco-dance", name: "Dance", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated low-angle view of people dancing on a glossy floor reflecting pink and blue disco lights", textColor: .white),
                ThemeImage(id: "disco-roller-skates", name: "Roller Skates", focalPoint: .center,
                           overlayOpacity: 0.38, accessibilityDescription: "AI-generated pink roller skates beside a mirrorball under pink and blue disco lights", textColor: .white),
                ThemeImage(id: "disco-last-dance", name: "Last Dance", focalPoint: UnitPoint(x: 0.62, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated image of two men embracing beneath a mirrorball under pink and blue dancefloor lights", textColor: .white),
                ThemeImage(id: "disco-vinyl", name: "Vinyl", focalPoint: .center,
                           overlayOpacity: 0.42, accessibilityDescription: "An AI-generated close-up of a vinyl record playing on a turntable beneath a mirrorball and pink and blue disco lights", textColor: .white),
                ThemeImage(id: "disco-mirrorball", name: "Mirrorball", focalPoint: UnitPoint(x: 0.60, y: 0.5),
                           overlayOpacity: 0.50, accessibilityDescription: "A mirrorball glowing under pink and blue disco spotlights", textColor: .white)
            ]
        case .outAndAbout:
            return [
                ThemeImage(id: "out-and-about-lakeside", name: "Lakeside", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of a sunlit alpine lakeside campground with people relaxing beneath trees beside blue water", textColor: .white),
                ThemeImage(id: "out-and-about-market", name: "Market", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of a bustling Mediterranean market street lined with flowers and stalls overlooking a sunny harbour", textColor: .white),
                ThemeImage(id: "out-and-about-pool-club", name: "Pool Club", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of a lively cliffside pool club with swimmers and sun loungers overlooking the Mediterranean Sea", textColor: .white),
                ThemeImage(id: "out-and-about-park", name: "Park", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of people picnicking and strolling through a sunny flower-filled city park beside a fountain", textColor: .white),
                ThemeImage(id: "out-and-about-harbour", name: "Harbour", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of a flower-lined Mediterranean harbour street filled with people and glowing lamps at golden hour", textColor: .white),
                ThemeImage(id: "out-and-about-carnival", name: "Carnival", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of a seaside carnival with a glowing Ferris wheel and crowds beneath a colourful sunset", textColor: .white)
            ]
        case .concrete:
            return [
                ThemeImage(id: "concrete-fjord", name: "Fjord", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of a concrete colonnade opening onto a fjord beneath a cloudy sky", textColor: .white),
                ThemeImage(id: "concrete-oculus", name: "Oculus", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of a circular skylight illuminating a monumental concrete interior", textColor: .white),
                ThemeImage(id: "concrete-sunlight", name: "Sunlight", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of angular sunlight falling across a concrete wall and bench", textColor: .white),
                ThemeImage(id: "concrete-pillar", name: "Pillar", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of a towering concrete pillar supporting a beam against a cloudy sky", textColor: .white),
                ThemeImage(id: "concrete-ivy", name: "Ivy", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of green ivy trailing over a textured concrete wall", textColor: .white),
                ThemeImage(id: "concrete-stairway", name: "Stairway", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of concrete stairs rising between angular walls toward an open sky", textColor: .white)
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
