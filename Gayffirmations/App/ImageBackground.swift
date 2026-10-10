import SwiftUI
import UIKit

/// Position the subject within an aspect-fill crop, consistently in previews and Today.
struct ImageBackground: View {
    let image: ThemeImage
    @Environment(\.appTheme) private var theme

    var body: some View {
        GeometryReader { geometry in
            if let uiImage = UIImage(named: image.id) {
                let scale = max(geometry.size.width / uiImage.size.width,
                                geometry.size.height / uiImage.size.height)
                let width = uiImage.size.width * scale
                let height = uiImage.size.height * scale
                Image(uiImage: uiImage)
                    .resizable()
                    .saturation(theme == .steel ? 0 : 1)
                    .frame(width: width, height: height)
                    .offset(x: -(width - geometry.size.width) * image.focalPoint.x,
                            y: -(height - geometry.size.height) * image.focalPoint.y)
                    .overlay(alignment: .topLeading) {
                        Color.black.opacity(image.overlayOpacity)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}
