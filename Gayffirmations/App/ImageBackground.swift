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
    @Environment(\.appTheme) private var theme
    @Environment(\.imageDimming) private var dimming

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
                        Color.black.opacity(ThemeBackgroundChoice.overlayOpacity(default: image.overlayOpacity, adjustment: dimming))
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}
