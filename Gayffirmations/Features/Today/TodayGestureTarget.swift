import SwiftUI
import UIKit

/// Taps reveal controls; horizontal swipes browse without blocking vertical scrolling.
struct TodayGestureTarget: UIViewRepresentable {
    var onTap: () -> Void
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap, onSwipeLeft: onSwipeLeft, onSwipeRight: onSwipeRight)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let swipeLeft = UISwipeGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.didSwipeLeft)
        )
        swipeLeft.direction = .left
        swipeLeft.delegate = context.coordinator

        let swipeRight = UISwipeGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.didSwipeRight)
        )
        swipeRight.direction = .right
        swipeRight.delegate = context.coordinator

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.didTap)
        )
        tap.require(toFail: swipeLeft)
        tap.require(toFail: swipeRight)
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(swipeLeft)
        view.addGestureRecognizer(swipeRight)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.onSwipeLeft = onSwipeLeft
        context.coordinator.onSwipeRight = onSwipeRight
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onTap: () -> Void
        var onSwipeLeft: () -> Void
        var onSwipeRight: () -> Void

        init(onTap: @escaping () -> Void, onSwipeLeft: @escaping () -> Void, onSwipeRight: @escaping () -> Void) {
            self.onTap = onTap
            self.onSwipeLeft = onSwipeLeft
            self.onSwipeRight = onSwipeRight
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            otherGestureRecognizer is UIPanGestureRecognizer
        }

        @objc func didTap() { onTap() }
        @objc func didSwipeLeft() { onSwipeLeft() }
        @objc func didSwipeRight() { onSwipeRight() }
    }
}
