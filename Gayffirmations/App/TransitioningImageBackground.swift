import SwiftUI

/// Keep the previous image underneath the incoming one until its transition finishes.
struct TransitioningImageBackground: View {
    let image: ThemeImage?
    let browsingForward: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedImage: ThemeImage?
    @State private var previousImage: ThemeImage?
    @State private var progress: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let previousImage {
                    ImageBackground(image: previousImage)
                }
                if let visibleImage = displayedImage ?? image {
                    ImageBackground(image: visibleImage)
                        .offset(x: reduceMotion ? 0 : (browsingForward ? 1 : -1)
                                * geometry.size.width * (1 - progress))
                        .opacity(reduceMotion ? progress : 1)
                }
            }
            .clipped()
            .task(id: image?.id) {
                guard let image else {
                    previousImage = nil
                    displayedImage = nil
                    progress = 1
                    return
                }
                guard displayedImage?.id != image.id else { return }
                guard displayedImage != nil else {
                    displayedImage = image
                    progress = 1
                    return
                }

                // Start at the edge without inheriting the message's animation.
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    previousImage = displayedImage
                    displayedImage = image
                    progress = 0
                }
                do { try await Task.sleep(for: .milliseconds(16)) }
                catch { return }
                withAnimation(.easeInOut(duration: reduceMotion ? 0.15 : 0.30),
                              completionCriteria: .removed) {
                    progress = 1
                } completion: {
                    guard displayedImage?.id == image.id else { return }
                    previousImage = nil
                }
            }
        }
        .accessibilityHidden(true)
    }
}
