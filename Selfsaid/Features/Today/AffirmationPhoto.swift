import SwiftUI

enum AffirmationPhoto: String, CaseIterable {
    case playful
    case confidence
    case selfWorth = "self-worth"

    var tag: String { rawValue }

    // Message centre as a fraction of the usable height: 0 = top, 1 = bottom.
    var portraitMessagePosition: CGFloat {
        switch self {
        case .playful, .confidence: 0.20
        case .selfWorth: 0.50
        }
    }

    var landscapeMessagePosition: CGFloat { 0.50 }

    var overlayOpacity: Double {
        switch self {
        case .playful, .confidence: 0.38
        case .selfWorth: 0.55
        }
    }

    func messagePosition(in size: CGSize) -> CGFloat {
        size.height > size.width ? portraitMessagePosition : landscapeMessagePosition
    }

    static func resolve(for affirmation: Affirmation?, selectedTags: [String]) -> Self? {
        guard let affirmation else { return nil }
        let matching = allCases.filter { photo in
            affirmation.tags.contains { $0.lowercased() == photo.tag }
        }
        // Prefer a selected tag, then use a consistent priority for mixed tags.
        for tag in selectedTags {
            if let photo = matching.first(where: { $0.tag == tag.lowercased() }) {
                return photo
            }
        }
        return matching.first
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
                .overlay(Color.black.opacity(photo.overlayOpacity))
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
