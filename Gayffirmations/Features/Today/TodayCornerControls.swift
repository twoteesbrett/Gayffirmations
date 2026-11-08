import SwiftUI

/// Layout and labels only; browsing, persistence, and navigation belong to callers.
struct TodayCornerControls: View {
    let affirmation: Affirmation?
    let isUpdating: Bool
    let showsImageInspection: Bool
    let isInspectingImage: Bool
    let onOpenDestination: (TodayDestination) -> Void
    let onToggleFavorite: () -> Void
    let onToggleImageInspection: () -> Void

    var body: some View {
        VStack {
            HStack {
                icon("books.vertical", label: "Library") { onOpenDestination(.library) }
                Spacer()
                icon(
                    affirmation?.isFavorite == true ? "heart.fill" : "heart",
                    label: affirmation?.isFavorite == true ? "Remove from favourites" : "Add to favourites",
                    action: onToggleFavorite
                )
                .disabled(affirmation == nil || isUpdating)
            }
            Spacer()
            HStack {
                if showsImageInspection {
                    icon(
                        isInspectingImage ? "eye.slash" : "eye",
                        label: isInspectingImage ? "Show affirmation" : "Inspect background image",
                        action: onToggleImageInspection
                    )
                }
                Spacer()
                icon("gearshape", label: "Settings") { onOpenDestination(.settings) }
            }
        }
        .padding(12)
    }

    private func icon(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .regular))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
