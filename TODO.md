# Selfsaid build plan

Work from top to bottom, keeping the app runnable after each milestone.

## 1. Affirmation basics

- [x] Define the `Affirmation` model.
- [x] Add a small set of bundled sample affirmations.
- [x] Show one affirmation in the existing app.
- [x] Add next and previous affirmation behavior.
- [x] Test selection behavior, including an empty collection.

## 2. Affirmation library

- [x] Display all affirmations in a library screen.
- [x] Add an affirmation.
- [x] Edit an affirmation.
- [x] Delete an affirmation.
- [x] Toggle favorite status.
- [x] Reject blank affirmation text.
- [x] Test add, edit, delete, favorite, and validation behavior.

## 3. Daily schedule logic

- [x] Define `AffirmationSchedule` with enabled state, start time, end time, and
      notifications per day.
- [x] Implement `ScheduleCalculator` for evenly spaced notification times.
- [x] Handle invalid time ranges and zero notifications.
- [x] Test common schedules and edge cases.
- [x] Show a plain-text preview of the calculated times.

## 4. Persistence

- [x] Save user-created affirmations and favorite status.
- [x] Save the notification schedule.
- [x] Load saved data when the app starts.
- [x] Confirm edits and schedule changes survive an app restart.

## 5. Local notifications

- [x] Add a notification-scheduling protocol.
- [ ] Request notification permission only when the user enables notifications.
- [ ] Schedule local notifications using affirmations from the library.
- [ ] Replace old pending notifications when the schedule changes.
- [ ] Remove pending notifications when the schedule is disabled.
- [ ] Explain how to enable notifications when permission has been denied.

## 6. Functional first-release interface

- [x] Create a Today screen.
- [x] Create a Library screen.
- [x] Create an affirmation editor.
- [x] Create a Schedule screen.
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
