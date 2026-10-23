import SwiftUI
import UIKit

private struct ImageDimmingKey: EnvironmentKey {
    static let defaultValue: Double = 0
}

extension EnvironmentValues {
    var imageDimming: Double {
        get { self[ImageDimmingKey.self] }
        set { self[ImageDimmingKey.self] = newValue }
    }
}

/// Position the subject within an aspect-fill crop, consistently in previews and Today.
struct ImageBackground: View {
    let image: ThemeImage
    var zoom: CGFloat = 1
    var panOffset: CGSize = .zero
    @Environment(\.appTheme) private var theme
    @Environment(\.imageDimming) private var dimming

    var body: some View {
        GeometryReader { geometry in
            if let uiImage = UIImage(named: image.id) {
                let scale = max(geometry.size.width / uiImage.size.width,
                                geometry.size.height / uiImage.size.height)
                let width = uiImage.size.width * scale * zoom
                let height = uiImage.size.height * scale * zoom
                let offset = ImageViewport.constrainedOffset(panOffset, zoom: zoom,
                    imageSize: uiImage.size, viewport: geometry.size, focalPoint: image.focalPoint)
                let x = -(uiImage.size.width * scale - geometry.size.width) * image.focalPoint.x * zoom
                    - geometry.size.width * (zoom - 1) / 2 + offset.width * geometry.size.width
                let y = -(uiImage.size.height * scale - geometry.size.height) * image.focalPoint.y * zoom
                    - geometry.size.height * (zoom - 1) / 2 + offset.height * geometry.size.height
                ZStack(alignment: .topLeading) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .interpolation(.high)
                        .saturation(theme == .steel ? 0 : 1)
                        .frame(width: width, height: height)
                        .offset(x: x, y: y)
                    Color.black.opacity(ThemeBackgroundChoice.overlayOpacity(default: image.overlayOpacity, adjustment: dimming))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}
