import SwiftUI

/// Renders the committed artwork or the two images in an interactive swipe.
struct TodayBackground: View {
    let swipeState: TodaySwipeState
    let imageInteraction: TodayImageInteractionState
    let browsingForward: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.themeImage) private var themeImage
    @Environment(\.appTheme) private var appTheme

    var body: some View {
        ZStack {
            appTheme.backgroundGradient
            if let swipe = swipeState.preview {
                GeometryReader { geometry in
                    ZStack {
                        if let image = swipe.currentImage {
                            ImageBackground(image: image, zoom: imageInteraction.zoom, panOffset: imageInteraction.offset)
                                .offset(x: reduceMotion ? 0 : swipeState.translation / swipe.width * geometry.size.width)
                                .opacity(reduceMotion ? 1 - swipeState.progress : 1)
                        }
                        if let image = swipe.nextImage {
                            ImageBackground(image: image)
                                .offset(x: reduceMotion ? 0 : (swipeState.translation / swipe.width + CGFloat(swipe.direction)) * geometry.size.width)
                                .opacity(reduceMotion ? swipeState.progress : 1)
                        }
                    }
                    .clipped()
                }
                .accessibilityHidden(true)
            } else {
                TransitioningImageBackground(image: themeImage, browsingForward: browsingForward,
                                             imageZoom: imageInteraction.zoom, imageOffset: imageInteraction.offset)
            }
        }
    }
}
