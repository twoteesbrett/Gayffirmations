import SwiftUI
import UIKit

/// Position the subject within an aspect-fill crop, consistently in previews and Today.
struct PhotoBackground: View {
    let photo: ThemePhoto
    @Environment(\.appTheme) private var theme

    var body: some View {
        GeometryReader { geometry in
            if let image = UIImage(named: photo.id) {
                let scale = max(geometry.size.width / image.size.width,
                                geometry.size.height / image.size.height)
                let width = image.size.width * scale
                let height = image.size.height * scale
                Image(uiImage: image)
                    .resizable()
                    .saturation(theme == .steel ? 0 : 1)
                    .frame(width: width, height: height)
                    .offset(x: -(width - geometry.size.width) * photo.focalPoint.x,
                            y: -(height - geometry.size.height) * photo.focalPoint.y)
                    .overlay(alignment: .topLeading) {
                        Color.black.opacity(photo.overlayOpacity)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}
