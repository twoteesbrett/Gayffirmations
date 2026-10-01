# gayaffirmations build plan

Work from top to bottom, keeping the app runnable after each milestone.
Complete the intended functionality before continuing visual polish.

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

- [x] Move Schedule into Settings, reachable from the Today menu.
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

## 8. Library organisation

- [x] Add optional tags to affirmations, allowing more than one tag per entry.
- [x] Add tag selection and creation to the affirmation editor.
- [x] Add Library filters for all affirmations, favourites, and individual tags.
- [x] Show a useful empty state when a filter has no matching affirmations.
- [x] Save and restore tags while keeping existing saved affirmations and
      favourite status compatible.
- [x] Test tag editing and loading existing saved data.
- [x] Test tag filtering.
- [x] Keep the initial scope simple: no tag colours, nested categories, or
      separate tag-management screen.

## 9. Affirmation selection and delivery

Use one shared selection for Today and reminders: all affirmations, or any
combination of favourites and tags. Include entries matching any chosen source
once each. Library now manages this shared selection for browsing, Today, and
reminders; Settings keeps appearance, notifications, and data controls.

- [x] Define a small selection model and one shared rule for finding matching
      affirmations; keep selection logic out of views and notification services.
- [x] Save and restore the selection, defaulting existing installations to all
      affirmations.
- [x] Manage the saved selection in Library and show the matching count.
- [x] Allow favourites and multiple tags together, without duplicate delivery.
- [x] Use the selected entries in Today while retaining next/previous behaviour.
- [x] Use the same selected entries when planning reminders, retaining the
      existing notification times and rotation through entries.
- [x] Refresh pending reminders when the selection changes or edits to text,
      tags, favourites, or library membership affect delivery.
- [x] Define and implement an empty-selection state: explain it in Today and
      Settings, remove pending reminders, preserve the chosen selection and
      schedule preference, and resume delivery when matching entries return.
- [x] Keep a selected tag identifiable when its last entry is removed so users
      can understand the empty state and choose another source.
- [x] Include selection in reset behaviour: reset-all restores all affirmations;
      restoring the library preserves selection and reevaluates matching entries.
- [x] Test selection matching, persistence compatibility, and failed saves.
- [x] Test Today navigation, reminder refresh and cancellation, recovery from
      an empty selection, reset behaviour, and scheduling failures.
- [x] Verify selection controls and empty states with Dynamic Type and VoiceOver.

  Source review completed: tag labels wrap, long source summaries stack, the
  decorative selection checkmark is hidden from VoiceOver, matching counts have
  an explicit accessibility label/value, and empty Today selections omit inactive
  navigation controls. Preview cases cover long/missing tags, no sources, and
  empty Today at the largest accessibility text size.
  User performed the guided live checks on 1 October 2026 and confirmed:
  - Large text leaves source labels readable, switches reachable, and the
    matching-count section scrollable.
  - Turning every source off shows a count of zero and a readable Today recovery
    message without navigation buttons; choosing All restores Today content.
  - VoiceOver announces All's selected state, favourites/tag labels and switch
    states, and the updated matching count. Recovery messages and the path back
    to All affirmations are reachable.
  Missing-tag and empty-library cases remain preview/source-review coverage.

## 10. Visual polish

- [x] Refine the Library layout around tag and favourites filters.

  First polish pass adds visible All, Favourites, and Tags controls, a tag
  selection sheet, a matching count, roomier rows, and theme-coloured 44-point
  favourite buttons. Library browsing supports favourites and multiple tags
  using the shared any-source matching rule for Library, Today, and reminders.
  Active tags wrap below the controls; clearing all filters shows all entries.
  Dark appearance and long-tag accessibility previews are included. Simulator
  build passes; live visual and VoiceOver review remains part of the final pass.
- [ ] Finalize the identity, typography, colors, and imagery for each theme.
- [ ] Refine each theme's light and dark appearance.

  Theme styling centralizes adaptive accent/background colours and typography.
  Today uses scalable, centred text over a fixed photo per theme and horizontal
  swipes to browse. The theme picker previews the same photos; app screens
  inherit the selected type design and follow system appearance. Eight Today
  previews cover every theme in light and dark.
  Simulator build passes; visual approval and final artwork remain pending.
- [ ] Replace temporary theme previews with final artwork.
- [ ] Add restrained transitions and haptics.
- [ ] Create an app icon and launch presentation.
- [ ] Perform a final accessibility and usability pass.

  Layout review centralizes theme backgrounds across all screens and sheets,
  preserves separate rounded Library sections, provides VoiceOver actions for
  Today browsing, and stacks theme previews at accessibility text sizes.
  Daily reminder controls also respect shared coordinator updates. Live visual
  and VoiceOver verification remains pending.

## Fixed category presets

- [x] Bundle 35 starter affirmations (five per preset), with multiple tags covering all 24 predefined tags. Existing saved libraries are preserved; restoring defaults loads the starter collection.

- [x] Define the seven fixed categories as presets of tags.
- [x] Share a Presets menu and flat tag list across Library and the editor; remove duplicate Settings selection controls.
- [x] Applying a preset replaces selected tags while preserving Favourites.
- [x] Recognize matching presets; show Custom selection for other tag combinations.
- [x] Offer predefined tags in the editor; offer available presets in the shared Library selection controls.
- [x] Persist Library choices through the reminder coordinator; Today supports swiping through the selected collection.
- [x] Review shared-selection ownership and save failures, keep Clear all available for custom-only libraries, and make the Library selection summary scroll with its entries at large text sizes.
- [x] Isolate previews from real notification scheduling and preserve unexpected saved value types.
- [ ] Perform live visual and accessibility review of shared selection controls.

## Later ideas

- [ ] Allow users to create and edit category presets. Initially use fixed presets:
  Feel Good (self-worth, confidence, joy); Playful (playful); Being Me (gay identity, pride,
  authenticity, shame); My Body (body image, appearance, masculinity, ageing);
  Love & Dating (dating, relationships, rejection, intimacy); Connection
  (friends, chosen family, belonging, loneliness); Tough Days (anxiety,
  setbacks, uncertainty, starting again). Custom tags remain available in the flat tag list.

- [ ] Select days of the week.
- [ ] Randomize delivery within each time section.
- [ ] Support overnight schedules.
- [ ] Add themed affirmation collections.
- [ ] Add a home-screen widget.
- [ ] Add sharing.
- [ ] Consider cloud sync.
