import SwiftUI

struct ThemePickerView: View {
    let store: ThemeStore

    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                ForEach(AppTheme.allCases) { theme in
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
            }

            if !store.selectedTheme.photos.isEmpty {
                Section {
                    Toggle("Use photos", isOn: Binding(
                        get: { store.backgroundChoice.usesPhoto },
                        set: { enabled in updateBackground { try store.setUsesPhoto(enabled) } }
                    ))

                    if store.backgroundChoice.usesPhoto {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 12)], spacing: 12) {
                            ForEach(store.selectedTheme.photos) { photo in
                                PhotoBackground(photo: photo)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .accessibilityHidden(false)
                                    .accessibilityLabel(photo.accessibilityDescription)
                            }
                        }
                    }
                } header: {
                    Text("Background")
                } footer: {
                    Text(store.backgroundChoice.usesPhoto
                         ? "Photos rotate with each affirmation."
                         : "Uses \(store.selectedTheme.name)’s colour background.")
                }
            }
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

    private func updateBackground(_ change: () throws -> Void) {
        do { try change() }
        catch { errorMessage = error.localizedDescription }
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
                    .font(.system(.title2, design: theme.fontDesign, weight: theme.affirmationWeight))
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

#if DEBUG
#Preview {
    let store = ThemeStore()
    NavigationStack {
        ThemePickerView(store: store)
    }
    .themeAppearance(store.selectedTheme)
}

#Preview("Disco with largest text size") {
    let store = ThemeStore(selectedTheme: .disco)
    NavigationStack {
        ThemePickerView(store: store)
    }
    .themeAppearance(store.selectedTheme)
    .environment(\.dynamicTypeSize, .accessibility5)

}
#endif

#if DEBUG
#Preview("Steel photos") {
    let store = ThemeStore(selectedTheme: .steel)
    let _ = try? store.setUsesPhoto(true)
    NavigationStack { ThemePickerView(store: store) }
        .themeAppearance(.steel)
}
#endif
