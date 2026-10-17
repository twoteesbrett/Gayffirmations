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
