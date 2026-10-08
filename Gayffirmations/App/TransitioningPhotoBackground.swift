import SwiftUI

/// Keep the previous photo underneath the incoming one until its transition finishes.
struct TransitioningPhotoBackground: View {
    let photo: ThemePhoto?
    let browsingForward: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedPhoto: ThemePhoto?
    @State private var previousPhoto: ThemePhoto?
    @State private var progress: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let previousPhoto {
                    PhotoBackground(photo: previousPhoto)
                }
                if let visiblePhoto = displayedPhoto ?? photo {
                    PhotoBackground(photo: visiblePhoto)
                        .offset(x: reduceMotion ? 0 : (browsingForward ? 1 : -1)
                                * geometry.size.width * (1 - progress))
                        .opacity(reduceMotion ? progress : 1)
                }
            }
            .clipped()
            .task(id: photo?.id) {
                guard let photo else {
                    previousPhoto = nil
                    displayedPhoto = nil
                    progress = 1
                    return
                }
                guard displayedPhoto?.id != photo.id else { return }
                guard displayedPhoto != nil else {
                    displayedPhoto = photo
                    progress = 1
                    return
                }

                // Start at the edge without inheriting the message's animation.
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    previousPhoto = displayedPhoto
                    displayedPhoto = photo
                    progress = 0
                }
                do { try await Task.sleep(for: .milliseconds(16)) }
                catch { return }
                withAnimation(.easeInOut(duration: reduceMotion ? 0.15 : 0.30),
                              completionCriteria: .removed) {
                    progress = 1
                } completion: {
                    guard displayedPhoto?.id == photo.id else { return }
                    previousPhoto = nil
                }
            }
        }
        .accessibilityHidden(true)
    }
}
