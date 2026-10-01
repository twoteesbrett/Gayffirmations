import SwiftUI

enum AffirmationPhoto: String, CaseIterable {
    case playful = "playful"
    case confidence = "confidence"
    case selfWorth = "self-worth"

    var tag: String {
        switch self {
        case .playful: "playful"
        case .confidence: "confidence"
        case .selfWorth: "self-worth"
        }
    }

    static func resolve(for affirmation: Affirmation?, selectedTags: [String]) -> Self? {
        guard let affirmation else { return nil }
        let matching = allCases.filter { photo in
            affirmation.tags.contains { $0.lowercased() == photo.tag }
        }
        // Prefer a selected tag, then use a consistent priority for mixed tags.
        return selectedTags.compactMap { tag in
            matching.first { $0.tag == tag.lowercased() }
        }.first ?? matching.first
    }
}

struct AffirmationPhotoBackground: View {
    let photo: AffirmationPhoto

    var body: some View {
        GeometryReader { geometry in
            Image(photo.rawValue)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay(Color.black.opacity(photo == .selfWorth ? 0.55 : 0.38))
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
