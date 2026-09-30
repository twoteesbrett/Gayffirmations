import Foundation

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case warm
    case midnight
    case playful
    case refined

    var id: Self { self }

    var name: String {
        switch self {
        case .warm:
            "Warm Coast"
        case .midnight:
            "Midnight"
        case .playful:
            "Playful Pop"
        case .refined:
            "Quiet Linen"
        }
    }

    var description: String {
        switch self {
        case .warm:
            "Soft sunset colors and an open, welcoming feel."
        case .midnight:
            "Deep tones with bright, confident accents."
        case .playful:
            "Cheerful color with a little more personality."
        case .refined:
            "Calm neutrals with a restrained, elegant feel."
        }
    }
}
