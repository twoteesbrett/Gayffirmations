import SwiftUI
import UIKit

/// Horizontal pans track the finger; vertical pans remain available to the scroll view.
struct TodayGestureTarget: UIViewRepresentable {
    var onTap: () -> Void
    var onDragChanged: (CGFloat) -> Void
    var onDragEnded: (CGFloat, CGFloat, Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(target: self) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didPan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = context.coordinator
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didTap))
        tap.require(toFail: pan)
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.target = self
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var target: TodayGestureTarget
        init(target: TodayGestureTarget) { self.target = target }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        @objc func didTap() { target.onTap() }

        @objc func didPan(_ pan: UIPanGestureRecognizer) {
            let translation = pan.translation(in: pan.view).x
            switch pan.state {
            case .began, .changed:
                target.onDragChanged(translation)
            case .ended, .cancelled, .failed:
                target.onDragEnded(translation, pan.velocity(in: pan.view).x, pan.state != .ended)
            default: break
            }
        }
    }
}
