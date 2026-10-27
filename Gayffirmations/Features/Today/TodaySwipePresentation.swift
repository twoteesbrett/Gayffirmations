import SwiftUI

/// The two scroll viewports share clipping but keep independent scroll positions.
struct TodaySwipePresentation<Page: View, Gesture: View>: View {
    let affirmation: Affirmation?
    let swipeState: TodaySwipeState
    let preventsTextScrolling: Bool
    let onInteraction: () -> Void
    @ViewBuilder let page: (Affirmation?, CGSize, CGFloat) -> Page
    @ViewBuilder let gesture: (CGFloat) -> Gesture
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appTheme) private var appTheme

    var body: some View {
        GeometryReader { geometry in
            // Balance the safe areas to keep the message at the screen's centre.
            let centeringInset = geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom
            // The destination has its own viewport, so its text height cannot resize
            // the current page or change the current page's vertical scroll position.
            ScrollView {
                page(
                    swipeState.preview?.current ?? affirmation,
                    geometry.size, centeringInset
                )
                .offset(x: reduceMotion ? 0 : swipeState.translation)
                .opacity(reduceMotion ? 1 - swipeState.progress : 1)
                .accessibilityHidden(swipeState.preview != nil)
                .overlay {
                    gesture(geometry.size.width)
                        .accessibilityHidden(true)
                }
            }
            .scrollClipDisabled()
            .scrollBounceBehavior(.basedOnSize)
            .scrollDisabled(preventsTextScrolling)
            // A committed destination starts at the top, matching its swipe preview.
            .id((swipeState.preview?.current ?? affirmation)?.id)
            .overlay {
                if let swipe = swipeState.preview {
                    ScrollView {
                        page(
                            swipe.next,
                            geometry.size, centeringInset
                        )
                        .foregroundStyle(swipe.nextImage?.textColor ?? appTheme.textColor)
                    }
                    .scrollClipDisabled()
                    .scrollBounceBehavior(.basedOnSize)
                    .offset(x: reduceMotion ? 0 : swipeState.translation + CGFloat(swipe.direction) * swipe.width)
                    .opacity(reduceMotion ? swipeState.progress : 1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            // Keep the resting layout inside the safe area, but let swiping text
            // reach the physical screen edges. Both scroll views use this clip.
            .frame(width: geometry.size.width, height: geometry.size.height)
            .padding(.leading, geometry.safeAreaInsets.leading)
            .padding(.trailing, geometry.safeAreaInsets.trailing)
            .clipped()
            .padding(.leading, -geometry.safeAreaInsets.leading)
            .padding(.trailing, -geometry.safeAreaInsets.trailing)
            .simultaneousGesture(
                DragGesture().onChanged { _ in onInteraction() }
            )
        }
    }
}
