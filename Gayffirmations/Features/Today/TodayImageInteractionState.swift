import SwiftUI

/// Image framing and gesture policy; the view supplies the current artwork's geometry.
struct TodayImageInteractionState {
    private(set) var zoom: CGFloat = 1
    private(set) var offset: CGSize = .zero
    private(set) var isPinching = false
    private(set) var isPanning = false
    private var pinchStartZoom: CGFloat = 1
    private var viewport: CGSize = .zero
    private var imageSize: CGSize = .zero
    private var focalPoint: UnitPoint = .center

    var preventsTextScrolling: Bool { zoom > 1 || isPinching || isPanning }

    mutating func updateGeometry(viewport: CGSize, imageSize: CGSize, focalPoint: UnitPoint) {
        self.viewport = viewport
        self.imageSize = imageSize
        self.focalPoint = focalPoint
        constrainOffset()
    }

    mutating func pinch(scale: CGFloat, ended: Bool) {
        isPinching = !ended
        zoom = min(4, max(1, pinchStartZoom * scale))
        constrainOffset()
        if ended { pinchStartZoom = zoom }
    }

    mutating func pan(translation: CGSize, ended: Bool) {
        isPanning = !ended
        offset.width += translation.width / max(1, viewport.width)
        offset.height += translation.height / max(1, viewport.height)
        constrainOffset()
    }

    mutating func reset() {
        zoom = 1
        pinchStartZoom = 1
        offset = .zero
        isPinching = false
        isPanning = false
    }

    private mutating func constrainOffset() {
        guard imageSize.width > 0, imageSize.height > 0 else {
            offset = .zero
            return
        }
        offset = ImageViewport.constrainedOffset(offset, zoom: zoom, imageSize: imageSize,
                                                 viewport: viewport, focalPoint: focalPoint)
    }
}
