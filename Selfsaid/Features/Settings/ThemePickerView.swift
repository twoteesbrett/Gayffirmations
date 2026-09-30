import SwiftUI

struct ThemePickerView: View {
    let store: ThemeStore

    @State private var errorMessage: String?

    var body: some View {
        List(AppTheme.allCases) { theme in
            Button {
                select(theme)
            } label: {
                ThemePreviewRow(
                    theme: theme,
                    isSelected: store.selectedTheme == theme
                )
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(
                store.selectedTheme == theme ? .isSelected : []
            )
        }
        .navigationTitle("Theme")
        .alert("Unable to Change Theme", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "The theme could not be saved.")
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func select(_ theme: AppTheme) {
        do {
            try store.select(theme)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ThemePreviewRow: View {
    let theme: AppTheme
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.backgroundGradient)
                .frame(width: 72, height: 58)
                .overlay {
                    Image(systemName: theme.symbol)
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(theme.accentColor)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.primary.opacity(0.12))
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(theme.name)
                    .font(.headline)
                Text(theme.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(theme.accentColor)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ThemePickerView(store: ThemeStore())
    }
}
