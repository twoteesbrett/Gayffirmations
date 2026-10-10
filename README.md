# Gayffirmations

Gayffirmations is an iOS affirmation app built as both a useful product and a way to
learn Swift and SwiftUI. The first goal is reliable, easy-to-read functionality;
visual polish will follow once the core behavior is working.

This README covers app behaviour and development. [SOURCES.md](SOURCES.md)
records bundled asset origins and preparation; [TODO.md](TODO.md) tracks
remaining work and verification.

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

## Bundled and personal messages

Bundled messages have read-only text and tags. You can favourite them, but
cannot delete them. Messages you create remain editable and deletable.
Existing starter messages with previously customised text or tags are preserved as
editable personal messages; untouched starter messages become bundled messages.

## Personalised messages

Settings includes an optional name. Tap the Name row to edit it, then Done to save
or Cancel to discard changes. Clearing the field and tapping Done removes it.
Built-in personalised messages use this name and are skipped in Today and reminders
when it is blank. For your own messages, write your name directly in the text.
Skipped messages remain editable in Library. Changing the name refreshes pending
reminders, and Reset All App Data clears it. Templates remain saved as templates.

## Scheduling behavior

Settings → Notifications → Schedules manages independent daily routines. Each has a
enabled state, content selection, time window, frequency, and rhythm.
Add a schedule, tap its summary to edit, or swipe to duplicate or delete it.
Edits use Save/Cancel; duplicates start disabled. The combined daily preview
shows every deliverable reminder and flags shared times.

Daily rhythm offers Evenly spaced,
More early, and More late while keeping the selected daily total fixed. Evenly
spaced divides the chosen period into equal sections and places one notification
in the middle of each section. Existing saved schedules retain this behavior.

For example, four notifications between 9:00 AM and 5:00 PM would arrive at
approximately 10:00 AM, 12:00 PM, 2:00 PM, and 4:00 PM.

More early and More late blend those positions with mirrored quadratic curves.
Gentle, Balanced, and Strong emphasis progressively shift more reminders toward
the chosen end of the daily period. A single reminder shifts too. The timeline
and expandable exact-time list preview the same times used for delivery. Rhythm
and emphasis are saved with the schedule; resetting restores Evenly spaced and
Balanced. At accessibility text sizes, the rhythm controls use menu pickers.

Each schedule independently selects All, favourites, or multiple tags. Combined
choices include entries matching any choice, once each. Empty selections or
selections without usable messages pause only that schedule; it resumes when
matching entries become available. Library’s All, Favourites, and Tags buttons
only filter its list for browsing and editing. Filters start at All when Library opens, and do not change Today
or reminders. Active choices are shown above the list with Clear filters.
Settings → Notifications → Schedules includes “When no schedule is active”
to choose Today’s fallback content: All affirmations, favourites, or tags.
New installations default to All; existing fallback choices are preserved.
The fallback also applies when enabled schedules have no usable messages.

Schedules are identified by their time range and affirmation selection, without
requiring a name. Existing installations preserve all delivery settings and copy
the old shared content selection once.

Today and notifications use the same combined daily plan. Today shows the most
recent scheduled affirmation across all enabled, deliverable schedules, keeping
the final reminder current overnight. Tied times retain saved schedule order;
Today shows the last of those reminders. Swiping browses the current schedule’s
content. With no deliverable reminders, Today rotates through the fallback selection
once per local calendar day.
Tap the screen to reveal corner icons for Library (top left), Favourite (top right),
Themes (bottom left), and Settings (bottom right). Tap again to hide them, or leave
them idle for five seconds. Interaction restarts the timer; opening a sheet clears
the controls. Dismissing a sheet reveals them with a fresh five-second timeout.
VoiceOver keeps them visible. Swiping left anywhere in the affirmation area advances to the
next affirmation; swiping right goes back. Message text slides in the swipe direction
and optional photos transition with it. Reduce Motion uses crossfades.
These temporary choices expire at
the next reminder, or at midnight without reminders. Changing a schedule or
the fallback selection clears the temporary choice. Library filters leave it
unchanged. VoiceOver exposes equivalent Next and Previous actions.

Each schedule requires the end time to be later than the start time on
the same day. Random times, selected weekdays, and overnight schedules can be
added later. Duplicate delivery minutes within one schedule are rejected; choose
a longer period, fewer reminders, or gentler emphasis. Different schedules may
share times, and both deliver. Counts must be between one and twenty-four per
schedule, with a maximum of twenty-four across enabled schedules, including
paused schedules. Disabled schedules do not use this budget.

## Notification sounds

The Sound picker in Settings offers None, Default, and five custom sounds:
Flute, Marimba, Choir, Harp, and Ahem.
Tapping a custom sound selects and previews it; tapping it again replays it.
A checkmark shows the selected sound, which applies immediately to all schedules.
Existing installations use the first saved schedule’s sound as the shared choice.
The choice persists even with no schedules. Resetting schedules keeps it; resetting
all app data restores Default. Sound previews stop when leaving the picker or backgrounding the app.
Notification playback follows the iPhone's sound and notification settings.

Custom previews use `AVAudioPlayer` and start immediately when a row is tapped.
Player creation, playback, and stopping run on a serial background queue so
audio-session work does not block the interface. Leaving the picker cancels
queued previews and stops playback; errors return to the main actor only for
the current preview.
Default has no in-app preview. Each planned reminder carries the selected sound
to `UNNotificationSound`; None omits its sound. Display names, Settings summaries,
and sound-row accessibility labels come from `NotificationSound.title`. Keep
saved identifiers and CAF filenames stable when renaming sounds so existing
selections continue to work. Audio preparation and file sizes are in
[SOURCES.md](SOURCES.md#notification-sounds).

## Themes and photos

The five themes are Eden, Disco, Steel, Concrete, and Out & About. Each has six photos.
Out & About rotates from morning through midday to evening: Lakeside, Market,
Pool Club, Park, Harbour, and Carnival.
Themes with photos use them by default and offer a Use photos switch saved
separately for each theme. Turning it off uses the theme's colour background.
The picker shows thumbnail previews. Steel renders photos in greyscale;
other themes retain colour. Source images retain their original colours.

Photos appear on Today; Library and Settings use the theme gradient. Each
photo has a crop focal point, dark overlay, and foreground colour chosen for
readability. Longer affirmations can scroll within the available space.

Photos advance when the displayed affirmation changes, including swipes and
scheduled changes. Swiping back reverses the photo sequence. The incoming
photo follows the message's swipe direction; Reduce Motion uses a crossfade.
The collection cycles in order. Rotation is session state and restarts at the
first photo on launch; only the Use photos preference is saved. Unrelated
view updates, favouriting, and opening Settings do not advance photos.
There is no separate timer or daily photo rotation.

To add photos, bundle image assets and add entries to `AppTheme.photos` with
stable IDs, descriptive accessibility labels, focal points, and checked
overlay and foreground settings. Record the originals in [SOURCES.md](SOURCES.md).
Check portrait and landscape crops, long affirmations, accessibility text
sizes, and toolbar contrast. Themes with photos automatically offer the switch.

## Saved-data compatibility

Startup preserves saved content and preferences. Initial starter content is
seeded once, using stable IDs and matching text to avoid duplicates; later
launches preserve edits and deletions. The earlier content-rebuild reset is
no longer performed, including for installations with an old rebuild marker.

Retired theme identifiers, including Nature and Refined, decode as Eden; current identifiers
retain their identity. Unknown or malformed data reports an error rather than silently
replacing saved content. Legacy fixed photo IDs are ignored when decoding
background preferences. Reset All clears saved background choices. Schedules
saved before sound selection was added load with Default sound.
Legacy schedules with zero reminders load with reminders disabled and a count
of one, preserving their times and sound. Delivery stays off until explicitly enabled.

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
├── Resources/Sounds/
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
`ScheduleValidation` enforces valid schedules and the combined daily budget.
`NotificationPlanner` builds the combined plan with schedule identities, matching
affirmations, and sounds; `TodayAffirmationResolver` consumes that same plan. An empty matching collection
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
