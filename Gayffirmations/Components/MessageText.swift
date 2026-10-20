import SwiftUI

struct MessageText: View {
    let source: String
    var theme: AppTheme? = nil

    var body: some View {
        let markup = MessageMarkup(source)
        markup.runs.reduce(Text(verbatim: "")) { text, run in
            var fragment = Text(verbatim: run.text)
            if run.style == .small {
                fragment = fragment.font(theme?.affirmationFont(for: .context) ?? .footnote)
            }
            return text + fragment
        }
        .accessibilityLabel(markup.plainText)
    }
}

/// Offset silhouettes keep the outline aligned with all fonts and inline markup.
struct TextOutline: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        content.background {
            if enabled {
                ZStack {
                    ForEach(0..<8) { index in
                        let angle = Double(index) * .pi / 4
                        content
                            .foregroundStyle(.black)
                            .colorMultiply(.black)
                            .offset(x: cos(angle) * 0.8, y: sin(angle) * 0.8)
                    }
                }
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            }
        }
    }
}
