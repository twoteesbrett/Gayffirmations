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
        .themedBackground()
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        artwork
                        Spacer()
                        selectionIndicator
                    }
                    description
                }
            } else {
                HStack(spacing: 16) {
                    artwork
                    description
                    Spacer(minLength: 8)
                    selectionIndicator
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    private var artwork: some View {
        theme.backgroundGradient
            .overlay {
                Text("Aa")
                    .font(.system(.title2, design: theme.fontDesign, weight: .medium))
                    .foregroundStyle(theme.textColor)
            }
            .frame(width: 72, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.primary.opacity(0.12))
            }
            .accessibilityHidden(true)
    }

    private var description: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(theme.name)
                .font(.headline)
            Text(theme.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(theme.accentColor)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    let store = ThemeStore()
    NavigationStack {
        ThemePickerView(store: store)
    }
    .environment(\.appTheme, store.selectedTheme)
    .tint(store.selectedTheme.accentColor)
    .fontDesign(store.selectedTheme.fontDesign)
}

#Preview("Largest text size in dark mode") {
    let store = ThemeStore()
    NavigationStack {
        ThemePickerView(store: store)
    }
    .environment(\.appTheme, store.selectedTheme)
    .tint(store.selectedTheme.accentColor)
    .fontDesign(store.selectedTheme.fontDesign)
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
