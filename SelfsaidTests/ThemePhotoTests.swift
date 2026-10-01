import Testing
import UIKit
@testable import Selfsaid

struct ThemePhotoTests {
    @Test("Every theme has its own bundled background", arguments: AppTheme.allCases)
    func bundledBackground(theme: AppTheme) {
        #expect(UIImage(named: theme.backgroundPhotoName) != nil)
    }

    @Test("Theme backgrounds use distinct assets")
    func distinctBackgrounds() {
        let names = AppTheme.allCases.map(\.backgroundPhotoName)
        #expect(Set(names).count == AppTheme.allCases.count)
    }
}
