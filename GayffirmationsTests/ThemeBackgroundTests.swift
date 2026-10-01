import Testing
import UIKit
@testable import Gayffirmations

struct ThemeBackgroundTests {
    @Test("Every configured photo is bundled", arguments: AppTheme.allCases)
    func configuredPhotoExists(theme: AppTheme) {
        if let name = theme.backgroundPhotoName {
            #expect(UIImage(named: name) != nil)
        }
    }
}
