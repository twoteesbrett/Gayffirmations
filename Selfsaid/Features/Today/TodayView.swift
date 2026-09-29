import SwiftUI

struct TodayView: View {
    let store: AffirmationStore
    @State private var deck: AffirmationDeck

    init(store: AffirmationStore) {
        self.store = store
        _deck = State(
            initialValue: AffirmationDeck(affirmations: store.affirmations)
        )
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if let affirmation = deck.currentAffirmation {
                Text("TODAY'S AFFIRMATION")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(affirmation.text)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Affirmation: \(affirmation.text)")
            } else {
                ContentUnavailableView(
                    "No Affirmations",
                    systemImage: "text.quote",
                    description: Text("Add an affirmation to begin.")
                )
            }

            Spacer()

            navigationControls
        }
        .padding()
        .onChange(of: store.affirmations) { _, updatedAffirmations in
            deck.replaceAffirmations(with: updatedAffirmations)
        }
    }

    private var navigationControls: some View {
        HStack(spacing: 40) {
            Button("Previous", systemImage: "chevron.left") {
                deck.showPrevious()
            }

            Button("Next", systemImage: "chevron.right") {
                deck.showNext()
            }
            .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.bordered)
        .disabled(!deck.canNavigate)
    }
}

#Preview("With affirmations") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
}

#Preview("Empty") {
    TodayView(store: AffirmationStore())
}
