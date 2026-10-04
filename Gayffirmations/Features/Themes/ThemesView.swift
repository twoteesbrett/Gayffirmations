import SwiftUI

/// Gives the theme picker its own modal navigation and dismissal.
struct ThemesView: View {
    let store: ThemeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ThemePickerView(store: store)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
