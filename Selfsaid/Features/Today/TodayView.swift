import SwiftUI

struct TodayView: View {
    let store: AffirmationStore
    @State private var deck: AffirmationDeck
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.appTheme) private var appTheme

    init(store: AffirmationStore) {
        self.store = store
        _deck = State(
            initialValue: AffirmationDeck(affirmations: store.affirmations)
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
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
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                .padding()
            }
        }
        .background(appTheme.backgroundGradient.ignoresSafeArea())
        .onChange(of: store.affirmations) { _, updatedAffirmations in
            deck.replaceAffirmations(with: updatedAffirmations)
        }
    }

    private var navigationControls: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    previousButton
                    nextButton
                }
            } else {
                HStack(spacing: 40) {
                    previousButton
                    nextButton
                }
            }
        }
        .buttonStyle(.bordered)
        .disabled(!deck.canNavigate)
    }

    private var previousButton: some View {
        Button("Previous", systemImage: "chevron.left") {
            deck.showPrevious()
        }
    }

    private var nextButton: some View {
        Button("Next", systemImage: "chevron.right") {
            deck.showNext()
        }
        .labelStyle(.titleAndIcon)
    }
}

#Preview("With affirmations") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
}

#Preview("Empty") {
    TodayView(store: AffirmationStore())
}

#Preview("Accessibility text size") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.dynamicTypeSize, .accessibility5)
}
