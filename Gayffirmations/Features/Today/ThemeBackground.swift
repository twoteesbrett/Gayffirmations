import SwiftUI

struct ThemeBackground: View {
    let theme: AppTheme

    var body: some View {
        theme.backgroundGradient.accessibilityHidden(true)
    }
}
