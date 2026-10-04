# Gayffirmations

Gayffirmations is an iOS affirmation app built as both a useful product and a way to
learn Swift and SwiftUI. The first goal is reliable, easy-to-read functionality;
visual polish will follow once the core behavior is working.

## First release

The first version should let someone:

- View the current affirmation and save it as a favourite from Today.
- Add, edit, and delete their own affirmations.
- Mark affirmations as favorites and organise them with tags.
- Choose all affirmations, or combine favorites and tags for Today and daily reminders.
- Keep affirmations and settings after closing the app.
- Choose how many affirmation notifications they receive each day.
- Define the daily period in which those notifications may arrive.
- Preview the calculated notification times before enabling the schedule.

Accounts, cloud sync, widgets, subscriptions, and generated affirmations are
intentionally outside the first release.

## Scheduling behavior

The initial scheduler will use the same schedule every day. It will divide the
chosen period into equal sections and place one notification in the middle of
each section.

For example, four notifications between 9:00 AM and 5:00 PM would arrive at
approximately 10:00 AM, 12:00 PM, 2:00 PM, and 4:00 PM.

Library, Today, and reminders share one saved selection managed in Library.
Choose All, favourites, or tags; presets select a set of available tags. Combined
choices include entries matching any choice, once each. The Tags button opens
the preset picker and individual tag controls. If the selected source has no entries, reminders pause while
retaining the enabled schedule and resume when matching entries return.

Today shows the most recent scheduled affirmation, keeping the final reminder
current overnight. With reminders off, it rotates once per local calendar day.
Tap the screen to reveal corner icons for Library (top left), Favourite (top right),
Themes (bottom left), and Settings (bottom right). Tap again to hide them, or leave
them idle for five seconds. Interaction restarts the timer; opening a sheet clears
the controls. Dismissing a sheet reveals them with a fresh five-second timeout.
VoiceOver keeps them visible. Swiping left anywhere in the affirmation area advances to the
next affirmation; swiping right goes back. Message text slides in the swipe direction
and optional photos transition with it. Reduce Motion uses crossfades.
These temporary choices expire at
the next reminder, or at midnight without reminders. Changing the schedule or
source selection clears the temporary choice. VoiceOver exposes equivalent
Next and Previous actions.

Themes with photos use them by default. Nature and Steel offer a photo switch,
saved separately for each theme; turning it off uses the colour background. Photos rotate as affirmations change
and follow the browsing direction; Reduce Motion uses a crossfade. The theme
picker shows the available photos. Text stays centred with a dark overlay over
photos for readability; longer text stays within margins and can scroll.

The first version will require the end time to be later than the start time on
the same day. Random times, selected weekdays, and overnight schedules can be
added later. Reminder combinations that round to duplicate delivery minutes
are rejected; choose a longer period or fewer reminders. Reminder counts must be
between zero and twelve, including changes made outside the UI.

## Technical direction

- Use SwiftUI for the interface.
- Keep views small and keep business rules out of views.
- Put notification-time calculations in a testable `ScheduleCalculator`.
- Put communication with `UNUserNotificationCenter` behind a notification
  service.
- Put saved-data access behind a repository so storage details do not spread
  throughout the app.
- Add architecture only when the app has a concrete need for it.

The current project structure is:

```text
Gayffirmations/
├── App/
├── Models/
├── Features/
│   ├── Today/
│   ├── Library/
│   ├── Schedule/
│   ├── Themes/
│   └── Settings/
├── Data/
├── Services/Notifications/
├── Stores/
└── Components/
```

Stores validate and persist their own state, updating observable values only after
successful saves. Startup preserves saved content and preferences. Initial starter
content is added once without replacing existing entries; later launches preserve
edits and deletions. Views send reminder-affecting schedule and source changes through
`NotificationCoordinator`, which serializes updates and restores prior reminders
when a save or replacement fails. Library edits notify that same coordinator through
store callbacks. `AppDataResetCoordinator` handles resets across all stores.

`AffirmationSelection` owns matching rules; `ScheduleCalculator` owns reminder times;
`NotificationPlanner` combines those times with affirmation text; and
`TodayAffirmationResolver` uses the same slot order. An empty matching collection
produces no reminders. Clearing the final Library filter returns to All.
`WrappingLayout` handles button placement without knowing about selections or storage. `TodayBrowsingState` owns temporary browsing,
wrapping, and expiry; `TodayView` owns gestures, animation, and presentation.
`AppDependencies` creates and connects shared services at launch, keeping the app
entry point focused on presenting its root view.

## Development approach

Build the app in small, complete slices. Each slice should have the minimum UI
needed to use it, tested behavior where appropriate, and readable names. Once
the first release works reliably, improve typography, colors, animation,
haptics, dark mode, and accessibility.

The active implementation checklist is in [TODO.md](TODO.md).
