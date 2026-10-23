import SwiftUI
import UIKit

/// Pans move zoomed artwork; otherwise horizontal pans browse affirmations.
struct TodayGestureTarget: UIViewRepresentable {
    var onTap: () -> Void
    var onDragChanged: (CGFloat) -> Void
    var onDragEnded: (CGFloat, CGFloat, Bool) -> Void
    var allowsImageZoom = false
    var onPinch: (CGFloat, Bool) -> Void = { _, _ in }
    var pansImage = false
    var onImagePan: (CGSize, Bool) -> Void = { _, _ in }

    func makeCoordinator() -> Coordinator { Coordinator(target: self) }

    func makeUIView(context: Context) -> GestureHostView {
        let view = GestureHostView()
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didPan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = context.coordinator
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didTap))
        tap.require(toFail: pan)
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didPinch(_:)))
        pinch.delegate = context.coordinator
        pinch.isEnabled = allowsImageZoom
        tap.require(toFail: pinch)
        let imagePan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didImagePan(_:)))
        imagePan.minimumNumberOfTouches = 2
        imagePan.maximumNumberOfTouches = 2
        imagePan.delegate = context.coordinator
        imagePan.isEnabled = allowsImageZoom
        tap.require(toFail: imagePan)
        view.viewportRecognizers = [tap, pan, pinch, imagePan]
        return view
    }

    func updateUIView(_ uiView: GestureHostView, context: Context) {
        context.coordinator.target = self
        uiView.installRecognizers()
        uiView.viewportRecognizers.compactMap { $0 as? UIPinchGestureRecognizer }
            .forEach { $0.isEnabled = allowsImageZoom }
        uiView.viewportRecognizers.compactMap { $0 as? UIPanGestureRecognizer }
            .filter { $0.minimumNumberOfTouches == 2 }
            .forEach { $0.isEnabled = allowsImageZoom }
    }

    static func dismantleUIView(_ uiView: GestureHostView, coordinator: Coordinator) {
        uiView.removeRecognizers()
    }

    /// Recognize touches throughout the scroll viewport, including empty space.
    /// The marker itself must not intercept the scroll view's hit testing.
    final class GestureHostView: UIView {
        var viewportRecognizers: [UIGestureRecognizer] = []
        private weak var installedScrollView: UIScrollView?

        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { false }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window == nil { removeRecognizers() }
            else { installRecognizers() }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            installRecognizers()
        }

        func installRecognizers() {
            var ancestor = superview
            while let view = ancestor {
                if let scrollView = view as? UIScrollView {
                    guard installedScrollView !== scrollView else { return }
                    removeRecognizers()
                    for recognizer in viewportRecognizers {
                        scrollView.addGestureRecognizer(recognizer)
                        if let pan = recognizer as? UIPanGestureRecognizer, pan.minimumNumberOfTouches == 1 {
                            scrollView.panGestureRecognizer.require(toFail: recognizer)
                        }
                    }
                    installedScrollView = scrollView
                    return
                }
                ancestor = view.superview
            }
        }

        func removeRecognizers() {
            for recognizer in viewportRecognizers {
                recognizer.view?.removeGestureRecognizer(recognizer)
            }
            installedScrollView = nil
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var target: TodayGestureTarget
        private var isPanningImage = false
        init(target: TodayGestureTarget) { self.target = target }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            if pan.minimumNumberOfTouches == 2 { return target.allowsImageZoom }
            if target.pansImage { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        @objc func didTap() { target.onTap() }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            guard target.allowsImageZoom,
                  gestureRecognizer.delegate === self, other.delegate === self else { return false }
            let pan = (gestureRecognizer as? UIPanGestureRecognizer) ?? (other as? UIPanGestureRecognizer)
            let hasPinch = gestureRecognizer is UIPinchGestureRecognizer || other is UIPinchGestureRecognizer
            return hasPinch && (pan?.minimumNumberOfTouches == 2 || (pan != nil && isPanningImage))
        }

        @objc func didImagePan(_ pan: UIPanGestureRecognizer) {
            let point = pan.translation(in: pan.view)
            switch pan.state {
            case .began, .changed, .ended, .cancelled, .failed:
                target.onImagePan(CGSize(width: point.x, height: point.y),
                                  pan.state == .ended || pan.state == .cancelled || pan.state == .failed)
                // Incremental movement lets pinch and pan update the same framing
                // without reapplying translation from earlier gesture events.
                pan.setTranslation(.zero, in: pan.view)
            default: break
            }
        }

        @objc func didPinch(_ pinch: UIPinchGestureRecognizer) {
            switch pinch.state {
            case .began, .changed:
                target.onPinch(pinch.scale, false)
            case .ended, .cancelled, .failed:
                target.onPinch(pinch.scale, true)
            default: break
            }
        }

        @objc func didPan(_ pan: UIPanGestureRecognizer) {
            if pan.state == .began { isPanningImage = target.pansImage }
            let point = pan.translation(in: pan.view)
            if isPanningImage {
                didImagePan(pan)
                if pan.state == .ended || pan.state == .cancelled || pan.state == .failed {
                    isPanningImage = false
                }
                return
            }
            let translation = point.x
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
