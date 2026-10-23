import SwiftUI
import Testing
@testable import Gayffirmations

@MainActor
struct TodayInteractionStateTests {
    @Test func imageGesturesAccumulateClampAndReset() {
        var state = TodayImageInteractionState()
        state.updateGeometry(viewport: CGSize(width: 100, height: 100),
                             imageSize: CGSize(width: 100, height: 100), focalPoint: .center)
        state.pinch(scale: 2, ended: false)
        #expect(state.zoom == 2)
        #expect(state.isPinching)
        #expect(state.preventsTextScrolling)
        state.pinch(scale: 2, ended: true)
        state.pinch(scale: 3, ended: true)
        #expect(state.zoom == 4)
        state.pan(translation: CGSize(width: 20, height: 10), ended: false)
        state.pan(translation: CGSize(width: 10, height: 20), ended: true)
        #expect(abs(state.offset.width - 0.3) < 0.001)
        #expect(abs(state.offset.height - 0.3) < 0.001)
        #expect(!state.isPanning)
        state.pan(translation: CGSize(width: 1000, height: -1000), ended: true)
        #expect(state.offset == CGSize(width: 1.5, height: -1.5))
        state.pinch(scale: 0.1, ended: true)
        #expect(state.zoom == 1)
        #expect(state.offset == .zero)
        #expect(!state.preventsTextScrolling)
        state.pinch(scale: 2, ended: false)
        state.pan(translation: CGSize(width: 10, height: 10), ended: false)
        state.reset()
        #expect(state.zoom == 1)
        #expect(state.offset == .zero)
        #expect(!state.preventsTextScrolling)
        state.pinch(scale: 1.5, ended: true)
        #expect(state.zoom == 1.5)
    }

    @Test(arguments: [1, -1]) func swipeSettlementRespectsDirectionVelocityAndCancellation(direction: Int) {
        var state = TodaySwipeState()
        state.preview = TodaySwipeState.Preview(
            current: Affirmation(text: "First"), next: Affirmation(text: "Next"),
            browsingState: TodayBrowsingState(), direction: direction, width: 100,
            currentImage: nil, nextImage: nil
        )
        let sign = CGFloat(direction)
        #expect(!state.shouldCommit(translation: -10 * sign, velocity: 0, cancelled: false))
        #expect(state.shouldCommit(translation: -40 * sign, velocity: 0, cancelled: false))
        #expect(state.shouldCommit(translation: -10 * sign, velocity: -200 * sign, cancelled: false))
        #expect(!state.shouldCommit(translation: -40 * sign, velocity: 300 * sign, cancelled: false))
        #expect(!state.shouldCommit(translation: -100 * sign, velocity: -200 * sign, cancelled: true))
        state.translation = -50 * sign
        #expect(state.progress == 0.5)
        state.isSettling = true
        state.reset()
        #expect(state.preview == nil)
        #expect(state.translation == 0)
        #expect(state.progress == 0)
        #expect(!state.isSettling)
    }
}
