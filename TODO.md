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
- [x] Request notification permission only when the user enables notifications.
- [x] Schedule local notifications using affirmations from the library.
- [x] Replace old pending notifications when the schedule changes.
- [x] Remove pending notifications when the schedule is disabled.
- [x] Explain how to enable notifications when permission has been denied.

## 6. Functional first-release interface

- [x] Create a Today screen.
- [x] Create a Library screen.
- [x] Create an affirmation editor.
- [x] Create a Schedule screen.
- [x] Check empty, loading, error, and permission-denied states.
- [x] Verify Dynamic Type and VoiceOver basics.

## 7. Settings and personalization

- [x] Replace the Schedule tab with a Settings tab.
- [x] Move the existing notification schedule into Settings.
- [x] Define a theme model that shares one layout and varies visual tokens such
      as color, typography, backgrounds, and imagery.
- [x] Add a theme picker with previews for three or four themes.
- [x] Save and restore the selected theme across app launches.
- [x] Add separate actions to restore the default affirmations and reset the
      notification schedule.
- [x] Add a confirmed reset-all action that restores affirmations, schedule,
      and theme defaults and removes pending notifications.
- [x] Test theme persistence and each reset path, including failure handling.
- [x] Verify that Settings and its confirmation dialogs work with Dynamic Type
      and VoiceOver.

## 8. Visual polish

- [ ] Finalize the identity, typography, colors, and imagery for each theme.
- [ ] Refine each theme's light and dark appearance.
- [ ] Replace temporary theme previews with final artwork.
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
