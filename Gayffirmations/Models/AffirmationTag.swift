nonisolated enum AffirmationTag: String, CaseIterable {
    case food
    case critic
    case gay
    case human
    case roleModel = "role-model"

    var name: String {
        switch self {
        case .food: "Food"
        case .critic: "Critic"
        case .gay: "Gay"
        case .human: "Human"
        case .roleModel: "Role Model"
        }
    }

    var displayName: String {
        switch self {
        case .food: "Food for Thought"
        case .critic: "The Itty Bitty Shitty Committee"
        case .gay: "Proudly Gay"
        case .human: "Being Human"
        case .roleModel: "Be the Man You Needed"
        }
    }

    /// Keep saved library tags and schedule selections working after category changes.
    static func canonicalTag(_ tag: String) -> String {
        switch tag.lowercased() {
        case "inner-critic": "critic"
        case "body", "confidence", "self-kindness": "human"
        default: tag
        }
    }

    static func canonicalTags(_ tags: [String]) -> [String] {
        tags.reduce(into: []) { result, tag in
            let value = canonicalTag(tag)
            if !result.contains(value) { result.append(value) }
        }
    }
}
