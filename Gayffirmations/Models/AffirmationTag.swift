enum AffirmationTag: String, CaseIterable {
    case body
    case food
    case confidence
    case gay
    case selfKindness = "self-kindness"

    var name: String {
        switch self {
        case .body: "Body"
        case .food: "Food"
        case .confidence: "Confidence"
        case .gay: "Gay"
        case .selfKindness: "Self-kindness"
        }
    }
}
