import SwiftUI

struct ThemePhotoBackground: View {
    let theme: AppTheme

    var body: some View {
        GeometryReader { geometry in
            Image(theme.backgroundPhotoName)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                // Keep white text readable even over the brightest parts of a photo.
                .overlay(Color.black.opacity(0.60))
        }
        .background(.black)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
