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
                    .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .accessibilityAddTraits(
                        store.selectedTheme == theme ? .isSelected : []
                    )
                }
            }

            if !store.selectedTheme.images.isEmpty {
                Section {
                    Toggle("Use images", isOn: Binding(
                        get: { store.backgroundChoice.usesImage },
                        set: { enabled in updateBackground { try store.setUsesImage(enabled) } }
                    ))

                    if store.backgroundChoice.usesImage {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 12)], spacing: 12) {
                            ForEach(store.selectedTheme.images) { image in
                                ImageBackground(image: image)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .accessibilityHidden(false)
                                    .accessibilityLabel(image.accessibilityDescription)
                            }
                        }
                    }
                } header: {
                    Text("Background")
                } footer: {
                    Text(store.backgroundChoice.usesImage
                         ? "Images rotate with each affirmation."
                         : "Uses \(store.selectedTheme.name)’s colour background.")
                }
            }
        }
        .themedBackground()
        .navigationTitle("Themes")
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
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .foregroundStyle(previewImage == nil ? theme.textColor : .white)
        .background {
            theme.backgroundGradient
                .overlay {
                    if let image = previewImage {
                        ImageBackground(image: image)
                            .environment(\.appTheme, theme)
                            .overlay {
                                LinearGradient(
                                    colors: [.black.opacity(0.40), .black.opacity(0.16)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                    }
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(isSelected ? 0.85 : 0.16), lineWidth: isSelected ? 2 : 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }

    /// Stable covers make the collections recognizable while browsing the picker.
    private var previewImage: ThemeImage? {
        let imageID: String?
        switch theme {
        case .eden: imageID = "eden-monstera"
        case .steel: imageID = "steel-strength"
        case .disco: imageID = "disco-mirrorball"
        case .concrete: imageID = "concrete-oculus"
        case .outAndAbout: imageID = "out-and-about-lakeside"
        }
        return theme.images.first { $0.id == imageID }
    }

    private var artwork: some View {
        theme.backgroundGradient
            .overlay {
                Text("Aa")
                    .affirmationTypography(theme, role: .preview)
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
                .foregroundStyle(previewImage == nil ? theme.textColor.opacity(0.85) : .white.opacity(0.9))
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(previewImage == nil ? theme.textColor : .black.opacity(0.8), .white)
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
#Preview("Steel images") {
    let store = ThemeStore(selectedTheme: .steel)
    let _ = try? store.setUsesImage(true)
    NavigationStack { ThemePickerView(store: store) }
        .themeAppearance(.steel)
}
#endif
