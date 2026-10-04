import Foundation
import Testing
@testable import Gayffirmations

@MainActor
struct TodayControlsStateTests {
    private let start = Date(timeIntervalSince1970: 1_000)

    @Test func tapRevealsAndSecondTapHides() {
        var state = TodayControlsState()
        #expect(!state.isVisible)
        state.toggle(at: start)
        #expect(state.isVisible)
        #expect(state.hideDeadline == start.addingTimeInterval(5))
        state.toggle(at: start.addingTimeInterval(1))
        #expect(!state.isVisible)
        #expect(state.hideDeadline == nil)
    }

    @Test func interactionExtendsTimeoutAndOldTimeoutCannotHideControls() {
        var state = TodayControlsState()
        state.toggle(at: start)
        let oldDeadline = start.addingTimeInterval(5)
        state.registerInteraction(at: start.addingTimeInterval(3))
        state.expire(deadline: oldDeadline, at: oldDeadline)
        #expect(state.isVisible)
        let newDeadline = start.addingTimeInterval(8)
        state.expire(deadline: newDeadline, at: start.addingTimeInterval(7))
        #expect(state.isVisible)
        state.expire(deadline: newDeadline, at: newDeadline)
        #expect(!state.isVisible)
        #expect(state.hideDeadline == nil)
    }

    @Test func swipingWhileHiddenDoesNotRevealControls() {
        var state = TodayControlsState()
        state.registerInteraction(at: start)
        #expect(!state.isVisible)
        #expect(state.hideDeadline == nil)
    }

    @Test func openingSheetOrLeavingAppClearsPendingTimeout() {
        var state = TodayControlsState()
        state.toggle(at: start)
        state.reset()
        #expect(!state.isVisible)
        #expect(state.hideDeadline == nil)
        state.toggle(at: start.addingTimeInterval(2))
        state.expire(deadline: start.addingTimeInterval(5), at: start.addingTimeInterval(5))
        #expect(state.isVisible)
    }

    @Test func sheetDismissalRevealsControlsWithFreshTimeout() {
        var state = TodayControlsState()
        state.toggle(at: start)
        state.reset()
        let dismissal = start.addingTimeInterval(60)
        state.show(at: dismissal)
        #expect(state.isVisible)
        #expect(state.hideDeadline == dismissal.addingTimeInterval(5))
        state.expire(deadline: start.addingTimeInterval(5), at: dismissal)
        #expect(state.isVisible)
        state.expire(deadline: dismissal.addingTimeInterval(5), at: dismissal.addingTimeInterval(5))
        #expect(!state.isVisible)
    }

    @Test func voiceOverKeepsControlsAvailableUntilDisabled() {
        var state = TodayControlsState()
        state.toggle(at: start)
        state.setAlwaysVisible(true)
        state.toggle(at: start)
        state.registerInteraction(at: start)
        state.expire(deadline: start.addingTimeInterval(5), at: start.addingTimeInterval(5))
        state.reset()
        state.show(at: start)
        #expect(state.isVisible)
        #expect(state.hideDeadline == nil)
        state.setAlwaysVisible(false)
        #expect(!state.isVisible)
    }
}
