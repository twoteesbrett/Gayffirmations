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
                        Image(systemName: appTheme.symbol)
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(appTheme.accentColor)
                            .accessibilityHidden(true)

                        Text("TODAY'S AFFIRMATION")
                            .font(.caption.weight(.semibold))
                            .tracking(2)
                            .foregroundStyle(.secondary)

                        Text(affirmation.text)
                            .font(appTheme.affirmationFont)
                            .lineSpacing(6)
                            .frame(maxWidth: 560)
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
                        VStack(spacing: 12) {
                            Text("\(deck.currentIndex + 1) of \(deck.affirmations.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Affirmation \(deck.currentIndex + 1) of \(deck.affirmations.count)")
                            navigationControls
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
        .themedBackground()
        .onChange(of: selectedAffirmations, initial: true) { _, updatedAffirmations in
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
                HStack(spacing: 16) {
                    previousButton
                    nextButton
                }
            }
        }
        .frame(maxWidth: 360)
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .disabled(!deck.canNavigate)
    }

    private var previousButton: some View {
        Button {
            deck.showPrevious()
        } label: {
            Label("Previous", systemImage: "chevron.left")
                .frame(maxWidth: .infinity)
        }
    }

    private var nextButton: some View {
        Button {
            deck.showNext()
        } label: {
            HStack {
                Text("Next")
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
        }
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

#Preview("Warm Coast — light") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .warm)
        .tint(AppTheme.warm.accentColor)
        .fontDesign(AppTheme.warm.fontDesign)
        .preferredColorScheme(.light)
}

#Preview("Warm Coast — dark") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .warm)
        .tint(AppTheme.warm.accentColor)
        .fontDesign(AppTheme.warm.fontDesign)
        .preferredColorScheme(.dark)
}

#Preview("Midnight — light") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .midnight)
        .tint(AppTheme.midnight.accentColor)
        .fontDesign(AppTheme.midnight.fontDesign)
        .preferredColorScheme(.light)
}

#Preview("Midnight — dark") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .midnight)
        .tint(AppTheme.midnight.accentColor)
        .fontDesign(AppTheme.midnight.fontDesign)
        .preferredColorScheme(.dark)
}

#Preview("Playful Pop — light") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .playful)
        .tint(AppTheme.playful.accentColor)
        .fontDesign(AppTheme.playful.fontDesign)
        .preferredColorScheme(.light)
}

#Preview("Playful Pop — dark") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .playful)
        .tint(AppTheme.playful.accentColor)
        .fontDesign(AppTheme.playful.fontDesign)
        .preferredColorScheme(.dark)
}

#Preview("Quiet Linen — light") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .refined)
        .tint(AppTheme.refined.accentColor)
        .fontDesign(AppTheme.refined.fontDesign)
        .preferredColorScheme(.light)
}

#Preview("Quiet Linen — dark") {
    TodayView(store: AffirmationStore(affirmations: Affirmation.samples))
        .environment(\.appTheme, .refined)
        .tint(AppTheme.refined.accentColor)
        .fontDesign(AppTheme.refined.fontDesign)
        .preferredColorScheme(.dark)
}
