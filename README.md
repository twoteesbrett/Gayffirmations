# Selfsaid

Selfsaid is an iOS affirmation app built as both a useful product and a way to
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
The menu opens Library and Settings. Swiping left anywhere in the affirmation area advances to the
next affirmation; swiping right goes back. These temporary choices expire at
the next reminder, or at midnight without reminders. Changing the schedule or
source selection clears the temporary choice. VoiceOver exposes equivalent
Next and Previous actions.

Today uses bundled photos for playful, confidence, self-worth, joy, authenticity,
and anxiety tags, with the theme gradient for other tags. Photo selection prefers a selected tag matching
the affirmation, then falls back to the order in `AffirmationPhoto`.
That file also holds each photo’s portrait and landscape message positions and
dark overlay strength. Positions describe the message centre as a fraction of
the available height; longer text stays within margins and can scroll.

The first version will require the end time to be later than the start time on
the same day. Random times, selected weekdays, and overnight schedules can be
added later.

## Technical direction

- Use SwiftUI for the interface.
- Keep views small and keep business rules out of views.
- Put notification-time calculations in a testable `ScheduleCalculator`.
- Put communication with `UNUserNotificationCenter` behind a notification
  service.
- Put saved-data access behind a repository so storage details do not spread
  throughout the app.
- Add architecture only when the app has a concrete need for it.

A likely project structure as the app grows is:

```text
Selfsaid/
├── App/
├── Models/
├── Features/
│   ├── Today/
│   ├── Library/
│   ├── Editor/
│   └── Schedule/
├── Data/
├── Services/
└── Components/
```

Folders should be introduced as their first files are added rather than being
created in advance.

## Development approach

Build the app in small, complete slices. Each slice should have the minimum UI
needed to use it, tested behavior where appropriate, and readable names. Once
the first release works reliably, improve typography, colors, animation,
haptics, dark mode, and accessibility.

The active implementation checklist is in [TODO.md](TODO.md).
