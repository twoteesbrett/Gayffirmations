import Foundation

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case warm
    case midnight
    case playful
    case refined
    case paper
    case slate
    case coast
    case forest
    case goldenHour
    case afterHours
    case cherry
    case bubblegum
    case daydream
    case muscle

    var id: Self { self }

    var name: String {
        switch self {
        case .warm: "Warm Coast"
        case .midnight: "Midnight"
        case .playful: "Playful Pop"
        case .refined: "Quiet Linen"
        case .paper: "Paper"
        case .slate: "Slate"
        case .coast: "Coast"
        case .forest: "Forest"
        case .goldenHour: "Golden Hour"
        case .afterHours: "After Hours"
        case .cherry: "Cherry"
        case .bubblegum: "Bubblegum"
        case .daydream: "Daydream"
        case .muscle: "Steel"
        }
    }

    var description: String {
        switch self {
        case .warm: "Soft sunset colors and an open, welcoming feel."
        case .midnight: "Deep tones with bright, confident accents."
        case .playful: "Cheerful color with a little more personality."
        case .refined: "Calm neutrals with a restrained, elegant feel."
        case .paper: "Warm ivory and thoughtful, timeless type."
        case .slate: "Soft charcoal with a quiet, understated feel."
        case .coast: "Sea-glass blues with a fresh, peaceful feel."
        case .forest: "Misty greens for a grounded, reflective mood."
        case .goldenHour: "Honey and peach with a warm, hopeful glow."
        case .afterHours: "Deep plum, blush accents, and a little temptation."
        case .cherry: "Rich cherry red with bold, cheeky confidence."
        case .bubblegum: "Pink and peach with an upbeat, playful spirit."
        case .daydream: "Lavender and pale blue for a light, whimsical mood."
        case .muscle: "Charcoal, steel, and bold type with a strong, focused feel."
        }
    }
}
