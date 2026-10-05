import Foundation

nonisolated enum NotificationSound: String, Codable, CaseIterable, Identifiable {
    case none
    case systemDefault = "default"
    case upliftingFlute = "uplifting-flute"
    case magicMarimba = "magic-marimba"
    case choirHarpBless = "choir-harp-bless"
    case relaxingHarpSweep = "relaxing-harp-sweep"
    case clearingTheThroat = "clearing-the-throat"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .systemDefault: "Default"
        case .none: "None"
        case .upliftingFlute: "Flute"
        case .magicMarimba: "Marimba"
        case .choirHarpBless: "Choir"
        case .relaxingHarpSweep: "Harp"
        case .clearingTheThroat: "Ahem"
        }
    }

    var filename: String? {
        switch self {
        case .systemDefault, .none: nil
        default: rawValue + ".caf"
        }
    }
}
