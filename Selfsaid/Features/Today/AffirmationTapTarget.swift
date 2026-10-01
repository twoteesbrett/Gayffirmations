import SwiftUI
import UIKit

/// Native recognizers let the double tap wait for a possible third tap without losing it.
struct AffirmationTapTarget: UIViewRepresentable {
    var onDoubleTap: () -> Void
    var onTripleTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDoubleTap: onDoubleTap, onTripleTap: onTripleTap)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.didDoubleTap)
        )
        doubleTap.numberOfTapsRequired = 2

        let tripleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.didTripleTap)
        )
        tripleTap.numberOfTapsRequired = 3

        doubleTap.require(toFail: tripleTap)
        view.addGestureRecognizer(doubleTap)
        view.addGestureRecognizer(tripleTap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onDoubleTap = onDoubleTap
        context.coordinator.onTripleTap = onTripleTap
    }

    final class Coordinator: NSObject {
        var onDoubleTap: () -> Void
        var onTripleTap: () -> Void

        init(onDoubleTap: @escaping () -> Void, onTripleTap: @escaping () -> Void) {
            self.onDoubleTap = onDoubleTap
            self.onTripleTap = onTripleTap
        }

        @objc func didDoubleTap() { onDoubleTap() }
        @objc func didTripleTap() { onTripleTap() }
    }
}
