import Foundation

/// A deliberately small markup vocabulary. Stored messages retain their source text.
nonisolated struct MessageMarkup {
    enum Style { case normal, small }
    struct Run {
        let text: String
        let style: Style
    }

    let runs: [Run]
    var plainText: String { runs.map(\.text).joined() }

    init(_ source: String) {
        var result: [Run] = []
        var remaining = source[...]
        var style = Style.normal
        while let tag = remaining.range(of: "</?small>|<br\\s*/?>", options: .regularExpression) {
            if remaining[tag].hasPrefix("<br") {
                result.append(Run(text: String(remaining[..<tag.lowerBound]) + "\n", style: style))
                remaining = remaining[tag.upperBound...]
                continue
            }
            let opening = remaining[tag] == "<small>"
            // Unbalanced or nested supported tags leave the whole message literal.
            guard opening == (style == .normal) else {
                runs = [Run(text: source, style: .normal)]
                return
            }
            if tag.lowerBound != remaining.startIndex {
                result.append(Run(text: String(remaining[..<tag.lowerBound]), style: style))
            }
            style = opening ? .small : .normal
            remaining = remaining[tag.upperBound...]
        }
        guard style == .normal else {
            runs = [Run(text: source, style: .normal)]
            return
        }
        if !remaining.isEmpty { result.append(Run(text: String(remaining), style: .normal)) }
        runs = result
    }
}
