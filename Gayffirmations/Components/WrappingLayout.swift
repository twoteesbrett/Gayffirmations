import SwiftUI

/// Keeps each item at its natural width and wraps only the items that do not fit.
struct WrappingLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? subviews.reduce(CGFloat.zero) {
            $0 + $1.sizeThatFits(.unspecified).width
        } + spacing * CGFloat(max(0, subviews.count - 1))
        let arrangement = arrange(subviews, width: width)
        return CGSize(width: width, height: arrangement.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let arrangement = arrange(subviews, width: bounds.width)
        for (index, item) in arrangement.items.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + item.origin.x, y: bounds.minY + item.origin.y),
                anchor: .topLeading,
                proposal: ProposedViewSize(item.size)
            )
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> (items: [CGRect], height: CGFloat) {
        var items: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let idealSize = subview.sizeThatFits(.unspecified)
            let size = subview.sizeThatFits(
                ProposedViewSize(width: min(idealSize.width, width), height: nil)
            )
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            items.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (items, y + rowHeight)
    }
}
