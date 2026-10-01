import SwiftUI

struct ThemeBackground: View {
    let theme: AppTheme
    let usesPhoto: Bool

    var body: some View {
        theme.backgroundGradient
            .overlay {
                if usesPhoto, let name = theme.backgroundPhotoName {
                    GeometryReader { geometry in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height,
                                   alignment: .center)
                            .clipped()
                            .overlay(Color.black.opacity(theme.photoOverlayOpacity))
                    }
                }
            }
            .accessibilityHidden(true)
    }
}
