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
        case .together:
            // Follow the series from first love in the 1970s to companionship around sixty.
            return [
                ThemeImage(id: "together-pickup-romance", name: "Pickup Romance", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of two young men sharing an affectionate moment on a pickup truck in the 1970s", textColor: .white),
                ThemeImage(id: "together-beach-camping", name: "Beach Camping", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of two young men preparing food together at a beach campsite", textColor: .white),
                ThemeImage(id: "together-sunny-shore", name: "Sunny Shore", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of two men walking arm in arm through shallow water at a sunny beach", textColor: .white),
                ThemeImage(id: "together-couch-reading", name: "Couch Reading", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of two men cuddling while reading together on a couch in the early 1980s", textColor: .white),
                ThemeImage(id: "together-kitchen", name: "Kitchen", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of two men embracing while preparing a meal in their 1980s kitchen", textColor: .white),
                ThemeImage(id: "together-cycling", name: "Cycling", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of two men consulting a map during a countryside cycling trip", textColor: .white),
                ThemeImage(id: "together-mountain-break", name: "Mountain Break", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of two men resting together beside a mountain lake", textColor: .white),
                ThemeImage(id: "together-coffee", name: "Coffee", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of two mature men sharing conversation over coffee at an outdoor café", textColor: .white),
                ThemeImage(id: "together-coastal-companionship", name: "Coastal Companionship", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of two older men sitting affectionately together by the coast at sunset", textColor: .white)
            ]
        case .ages:
            return [
                ThemeImage(id: "ages-harbour-bus-stop", name: "Harbour Bus Stop", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A young man with a shoulder bag waiting at a harbour bus stop", textColor: .white),
                ThemeImage(id: "ages-university", name: "University", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A young man studying at a library table", textColor: .white),
                ThemeImage(id: "ages-quiet-support", name: "Quiet Support", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A man comforting another with an arm around his shoulders", textColor: .white),
                ThemeImage(id: "ages-seaside-campfire", name: "Seaside Campfire", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Friends gathered around a seaside campfire at sunset", textColor: .white),
                ThemeImage(id: "ages-office", name: "Office", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Two men smiling over their work in a 1980s office", textColor: .white),
                ThemeImage(id: "ages-coastal-walk", name: "Coastal Walk", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Two men walking arm in arm along a rain-soaked coastal road", textColor: .white),
                ThemeImage(id: "ages-kitchen", name: "Kitchen", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Two men embracing while cooking in a vintage kitchen", textColor: .white),
                ThemeImage(id: "ages-moving-boxes", name: "Moving Boxes", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A man looking at a photograph while sitting among moving boxes", textColor: .white),
                ThemeImage(id: "ages-garden-harvest", name: "Garden Harvest", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Two men smiling as they harvest carrots in a sunny garden", textColor: .white)
            ]
        case .steel:
            return [
                ThemeImage(id: "steel-strength", name: "Strength", focalPoint: UnitPoint(x: 0.85, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated monochrome portrait of a standing man curling a barbell", textColor: .white),
                ThemeImage(id: "steel-squat", name: "Squat", focalPoint: UnitPoint(x: 0.55, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated monochrome portrait of a man squatting with a barbell", textColor: .white),
                ThemeImage(id: "steel-lunge", name: "Lunge", focalPoint: .center,
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated monochrome portrait of a man lunging with dumbbells", textColor: .white),
                ThemeImage(id: "steel-deadlift", name: "Deadlift", focalPoint: UnitPoint(x: 0.52, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "A monochrome portrait of a man preparing to deadlift a barbell", textColor: .white),
                ThemeImage(id: "steel-bench-press", name: "Bench Press", focalPoint: UnitPoint(x: 0.45, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated monochrome portrait of a man bench pressing a barbell", textColor: .white),
                ThemeImage(id: "steel-pull-up", name: "Pull-up", focalPoint: .center,
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated monochrome portrait of a man doing a pull-up, viewed from behind", textColor: .white),
                ThemeImage(id: "steel-lateral-raise", name: "Lateral Raise", focalPoint: UnitPoint(x: 0.55, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "An AI-generated monochrome portrait of a man raising dumbbells out to his sides", textColor: .white),
                ThemeImage(id: "steel-curl", name: "Curl", focalPoint: UnitPoint(x: 0.70, y: 0.5),
                           overlayOpacity: 0.38, accessibilityDescription: "A monochrome portrait of a seated man curling a dumbbell", textColor: .white),
                ThemeImage(id: "steel-release", name: "Release", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated monochrome portrait of a man lifting a kettlebell with his head tilted back", textColor: .white)
            ]
        case .gayWonderland:
            // Follow the Pride rainbow, with transitional shades between the main colours.
            return [
                ThemeImage(id: "gay-wonderland-crimson-archway", name: "Crimson Archway", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Red drapery and flowers frame men and classical stonework beneath a crimson sun", textColor: .white),
                ThemeImage(id: "gay-wonderland-coral-paradise", name: "Coral Paradise", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Men lounge by a turquoise pool under a coral sky with floating lips and flowers", textColor: .white),
                ThemeImage(id: "gay-wonderland-orange-desert", name: "Orange Desert", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A surreal orange desert with giant sculptural figures and a turquoise pool", textColor: .white),
                ThemeImage(id: "gay-wonderland-amber-hourglass", name: "Amber Hourglass", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A giant hourglass towers above men, sunflowers, and amber desert arches", textColor: .white),
                ThemeImage(id: "gay-wonderland-golden-pool", name: "Golden Pool", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Men lounge beside a pool framed by yellow flowers and golden arches", textColor: .white),
                ThemeImage(id: "gay-wonderland-emerald-pool", name: "Emerald Pool", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Men gather by an emerald pool and waterfall cradled in a giant stone hand", textColor: .white),
                ThemeImage(id: "gay-wonderland-blue-oasis", name: "Blue Oasis", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Men stand amid blue waterfalls, white arches, and giant blue flowers", textColor: .white),
                ThemeImage(id: "gay-wonderland-indigo-waterfall", name: "Indigo Waterfall", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Men lounge beside indigo waterfalls beneath a full moon and blue orchids", textColor: .white),
                ThemeImage(id: "gay-wonderland-violet-portal", name: "Violet Portal", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Men stand among violet arches, floating spheres, and purple orchids above still water", textColor: .white)
            ]
        case .shitHappens:
            return [
                ThemeImage(id: "shit-happens-mirror-check", name: "Mirror Check", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A man in an untied bow tie examines his nose in a bathroom mirror", textColor: .white),
                ThemeImage(id: "shit-happens-burnt-toast", name: "Burnt Toast", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A man holds up two charred slices of toast beside a smoking toaster", textColor: .white),
                ThemeImage(id: "shit-happens-cafe-laughter", name: "Café Laughter", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A man looks up from his outdoor café table while his companion laughs", textColor: .white),
                ThemeImage(id: "shit-happens-laundromat", name: "Laundromat", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A man holds up a shrunken rainbow tank top at a laundromat", textColor: .white),
                ThemeImage(id: "shit-happens-matching-shirts", name: "Matching Shirts", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "Two men react to wearing matching hibiscus shirts at a garden party", textColor: .white),
                ThemeImage(id: "shit-happens-coffee-spill", name: "Coffee Spill", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A man looks down at coffee spilled across his shirt while his companion laughs", textColor: .white),
                ThemeImage(id: "shit-happens-muddy-trail", name: "Muddy Trail", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A man sits in the mud while his companion leans over to help and a dog stands nearby", textColor: .white),
                ThemeImage(id: "shit-happens-poolside-chair", name: "Poolside Chair", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A man sits in a collapsed poolside chair while his friends laugh", textColor: .white),
                ThemeImage(id: "shit-happens-park-yoga", name: "Park Yoga", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "A man gives a sheepish smile while holding a downward dog pose in the park", textColor: .white)
            ]
        case .outAndAbout:
            return [
                ThemeImage(id: "out-and-about-lakeside-cafe", name: "Lakeside Café", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of men enjoying a café beside a lake", textColor: .white),
                ThemeImage(id: "out-and-about-market", name: "Market", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of men sharing an embrace at a golden seaside market", textColor: .white),
                ThemeImage(id: "out-and-about-greenhouse-garden", name: "Greenhouse Garden", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of men gathering in a sunlit greenhouse garden", textColor: .white),
                ThemeImage(id: "out-and-about-beach", name: "Beach", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of men sharing a romantic moment on a sunny Mediterranean beach", textColor: .white),
                ThemeImage(id: "out-and-about-villa-pool", name: "Villa Pool", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of men gathering beside a sunlit villa pool", textColor: .white),
                ThemeImage(id: "out-and-about-waterfall", name: "Waterfall", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of men picnicking beside a waterfall", textColor: .white),
                ThemeImage(id: "out-and-about-thermal-baths", name: "Thermal Baths", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of men relaxing at coastal thermal baths at sunset", textColor: .white),
                ThemeImage(id: "out-and-about-twilight-dinner", name: "Twilight Dinner", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of two men dining together at Mediterranean twilight", textColor: .white),
                ThemeImage(id: "out-and-about-moonlit-piazza", name: "Moonlit Piazza", focalPoint: .center,
                           overlayOpacity: 0.48, accessibilityDescription: "An AI-generated image of men strolling through a moonlit Mediterranean piazza", textColor: .white)
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
