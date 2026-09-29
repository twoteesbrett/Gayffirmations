import Foundation

struct Affirmation: Identifiable, Equatable {
    let id: UUID
    var text: String
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        text: String,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.text = text
        self.isFavorite = isFavorite
    }
}

extension Affirmation {
    static let samples = [
        Affirmation(text: "I am capable of handling what today brings."),
        Affirmation(text: "Small steps still move me forward."),
        Affirmation(text: "I can give myself the patience I give to others."),
        Affirmation(text: "My effort matters, even when progress feels quiet."),
        Affirmation(text: "I am allowed to learn at my own pace.")
    ]
}
