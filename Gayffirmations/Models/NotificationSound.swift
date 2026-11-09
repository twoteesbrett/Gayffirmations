import Foundation

nonisolated enum NotificationSound: String, Codable, CaseIterable, Identifiable {
    case none
    case systemDefault = "default"
    case clearingTheThroat = "clearing-the-throat"
    case choirRingtone = "freesound_community-choir-notification-ringtone-tone-e-major-95172"
    case choirHarpBless = "choir-harp-bless"
    case podcastIntro = "bombinsound-podcast-music-intro-logo-version-ridingx27-617274"
    case horrorScream = "universfield-male-horror-scream-02-123079"
    case funnyYodel = "samuel_copier_country-a-funny-yodel-401529"

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "uplifting-flute", "magic-marimba", "relaxing-harp-sweep":
            self = .systemDefault
        default:
            guard let sound = Self(rawValue: value) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown notification sound: \(value)")
            }
            self = sound
        }
    }

    var title: String {
        switch self {
        case .none: "None"
        case .systemDefault: "Default"
        case .clearingTheThroat: "Ahem"
        case .choirRingtone: "Choir"
        case .choirHarpBless: "Harp"
        case .podcastIntro: "Hip Hop"
        case .horrorScream: "Scream"
        case .funnyYodel: "Yodel"
        }
    }

    var filename: String? {
        switch self {
        case .systemDefault, .none: nil
        default: rawValue + ".caf"
        }
    }
}
