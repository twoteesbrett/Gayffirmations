import SwiftUI

struct TodayView: View {
    let store: AffirmationStore
    let selectionStore: AffirmationSelectionStore
    @State private var deck: AffirmationDeck
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.appTheme) private var appTheme

    init(store: AffirmationStore, selectionStore: AffirmationSelectionStore? = nil) {
        let selectionStore = selectionStore ?? AffirmationSelectionStore()
        self.selectionStore = selectionStore
        self.store = store
        _deck = State(
            initialValue: AffirmationDeck(affirmations: selectionStore.selection.matchingAffirmations(in: store.affirmations))
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
                            "No Matching Affirmations",
                            systemImage: "text.quote",
                            description: Text(selectionStore.selection.emptyMessage)
                        )
                    }

                    Spacer()

                    if deck.currentAffirmation != nil {
                        navigationControls
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
        .background(appTheme.backgroundGradient.ignoresSafeArea())
        .onChange(of: selectedAffirmations) { _, updatedAffirmations in
            deck.replaceAffirmations(with: updatedAffirmations)
        }
    }

    private var selectedAffirmations: [Affirmation] {
        selectionStore.selection.matchingAffirmations(in: store.affirmations)
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

#Preview("Empty selection at largest text size") {
    TodayView(
        store: AffirmationStore(affirmations: Affirmation.samples),
        selectionStore: AffirmationSelectionStore(selection: .tag("Finding calm during a busy working day"))
    )
    .environment(\.dynamicTypeSize, .accessibility5)
}
