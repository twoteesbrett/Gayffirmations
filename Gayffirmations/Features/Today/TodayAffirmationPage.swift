import SwiftUI

/// Message typography, accessibility actions, and space reserved for controls.
struct TodayAffirmationPage<EmptyContent: View>: View {
    let affirmation: Affirmation?
    let size: CGSize
    let centeringInset: CGFloat
    let browsingForward: Bool
    let outlinesText: Bool
    let onCycle: (Int) -> Void
    @ViewBuilder let emptyContent: () -> EmptyContent
    @Environment(\.appTheme) private var appTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let affirmation {
                affirmationMessage(affirmation)
                    .id(affirmation.id)
                    .transition(browsingTransition(width: size.width))
            } else {
                emptyContent()
            }
        }
        // Reserve room for the controls even while hidden, so text never jumps.
        .padding(.horizontal, 28)
        .padding(.top, 68 + max(0, -centeringInset))
        .padding(.bottom, 68 + max(0, centeringInset))
        .frame(maxWidth: .infinity, minHeight: size.height)
    }

    private func affirmationMessage(_ affirmation: Affirmation) -> some View {
        MessageText(source: affirmation.text, theme: appTheme)
            .affirmationTypography(appTheme)
            .lineSpacing(appTheme.affirmationLineSpacing)
            .frame(maxWidth: 560)
            .multilineTextAlignment(.center)
            .modifier(TextOutline(enabled: outlinesText))
            .accessibilityLabel("Affirmation: \(MessageMarkup(affirmation.text).plainText)")
            .accessibilityAction(named: "Next affirmation") { onCycle(1) }
            .accessibilityAction(named: "Previous affirmation") { onCycle(-1) }
    }

    private func browsingTransition(width: CGFloat) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        let distance = browsingForward ? width : -width
        return .asymmetric(
            insertion: .offset(x: distance),
            removal: .offset(x: -distance)
        )
    }

}
