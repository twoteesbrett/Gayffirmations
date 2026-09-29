# Selfsaid build plan

Work from top to bottom, keeping the app runnable after each milestone.

## 1. Affirmation basics

- [x] Define the `Affirmation` model.
- [x] Add a small set of bundled sample affirmations.
- [x] Show one affirmation in the existing app.
- [x] Add next and previous affirmation behavior.
- [x] Test selection behavior, including an empty collection.

## 2. Affirmation library

- [ ] Display all affirmations in a library screen.
- [ ] Add an affirmation.
- [ ] Edit an affirmation.
- [ ] Delete an affirmation.
- [ ] Toggle favorite status.
- [ ] Reject blank affirmation text.
- [ ] Test add, edit, delete, favorite, and validation behavior.

## 3. Daily schedule logic

- [ ] Define `AffirmationSchedule` with enabled state, start time, end time, and
      notifications per day.
- [ ] Implement `ScheduleCalculator` for evenly spaced notification times.
- [ ] Handle invalid time ranges and zero notifications.
- [ ] Test common schedules and edge cases.
- [ ] Show a plain-text preview of the calculated times.

## 4. Local notifications

- [ ] Add a notification-scheduling protocol.
- [ ] Request notification permission only when the user enables notifications.
- [ ] Schedule local notifications using affirmations from the library.
- [ ] Replace old pending notifications when the schedule changes.
- [ ] Remove pending notifications when the schedule is disabled.
- [ ] Explain how to enable notifications when permission has been denied.

## 5. Persistence

- [ ] Save user-created affirmations and favorite status.
- [ ] Save the notification schedule.
- [ ] Load saved data when the app starts.
- [ ] Confirm edits and schedule changes survive an app restart.

## 6. Functional first-release interface

- [ ] Create a Today screen.
- [ ] Create a Library screen.
- [ ] Create an affirmation editor.
- [ ] Create a Schedule screen.
- [ ] Check empty, loading, error, and permission-denied states.
- [ ] Verify Dynamic Type and VoiceOver basics.

## 7. Visual polish

- [ ] Establish typography and colors.
- [ ] Refine light and dark appearances.
- [ ] Add restrained transitions and haptics.
- [ ] Create an app icon and launch presentation.
- [ ] Perform a final accessibility and usability pass.

## Later ideas

- [ ] Select days of the week.
- [ ] Randomize delivery within each time section.
- [ ] Support overnight schedules.
- [ ] Add themed affirmation collections.
- [ ] Add a home-screen widget.
- [ ] Add sharing.
- [ ] Consider cloud sync.
