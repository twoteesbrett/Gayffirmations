import SwiftUI

extension ToolbarContent {
    @ToolbarContentBuilder
    func iconOnlyBackground() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            self.sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
