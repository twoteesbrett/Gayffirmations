import SwiftUI

/// Positions the message by its centre, while keeping all content inside the scroll area.
struct AffirmationMessageLayout: Layout {
    let viewportHeight: CGFloat
    let centreFraction: CGFloat
    private let verticalMargin: CGFloat = 24

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let content = subviews.first?.sizeThatFits(
            ProposedViewSize(width: width, height: nil)
        ) ?? .zero
        return CGSize(width: width, height: max(viewportHeight, content.height + verticalMargin * 2))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let content = subviews.first else { return }
        let contentProposal = ProposedViewSize(width: bounds.width, height: nil)
        let height = content.sizeThatFits(contentProposal).height
        let preferred = viewportHeight * min(max(centreFraction, 0), 1)
        let centre = min(
            max(preferred, verticalMargin + height / 2),
            bounds.height - verticalMargin - height / 2
        )
        content.place(
            at: CGPoint(x: bounds.midX, y: bounds.minY + centre),
            anchor: .center,
            proposal: contentProposal
        )
    }
}
