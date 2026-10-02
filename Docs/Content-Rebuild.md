# Content rebuild and multiple photos per theme

## Current baseline

The shipped catalogue has four visual themes (Nature, Steel, Refined, and Disco), 15 initial affirmations, five initial tags (body, food, confidence, gay, and self-kindness), and optional photos for Nature (three) and Steel (four). Colours remain the default. Library editing, custom tags, favourites, selections, scheduling, persistence, and accessibility remain available.

On the next launch, a one-time content revision clears saved affirmations (including favourites and tags), the selected theme, source selections, and the old photo toggle. Reminder schedules remain saved; launch reconciliation removes reminders when there are no eligible affirmations. New content created after that launch is preserved. The initial affirmation catalogue is seeded once, including into an empty library saved by the baseline version. Stable IDs and matching text prevent duplicate starters; subsequent edits and deletions are preserved. Before clearing preferences, the repository saves the old content in `gayffirmations.contentBeforeRebuild`. Removed bundled content is also backed up outside the project at `/private/tmp/gayffirmations-content-before-reset.zip`.

Neutral and retired theme identifiers decode as Nature. Current theme identifiers retain their identity. Unknown or malformed saved data still reports an error. Retired identifiers are retained only for migration.

## Implemented photo baseline

Nature offers Night sky, Forest, and Coast; Steel offers Strength, Presence, Release, and Water. Both use the same Use photos toggle and thumbnail previews. Each photo has a stable asset ID, crop focal point, individual dark overlay and light foreground. Steel renders its photos in greyscale on Today and in thumbnail previews; source assets retain their original colours and other themes render in colour. Colours/Photo mode is saved per theme. Photos advance through the theme’s collection whenever the displayed affirmation changes, including swipes and scheduled changes; unrelated view updates do not advance them. Today alone displays photos, while Library and Settings use the theme gradient. Legacy fixed photo IDs are ignored when decoding preferences. Themes without photos use colours. Reset All clears saved background choices. There is no timer or daily photo rotation.

## Adding photos to other themes

Add bundled JPEG assets and entries to the theme’s photo collection, with stable IDs, descriptive accessibility labels, focal points and individually checked foreground/overlay settings. Update PHOTO_SOURCES.md with the supplied source files. A theme with photos automatically offers the Use photos toggle.

Swiping left advances both affirmation and photo; swiping right goes back through both. Scheduled affirmation changes advance photos. During swipes, the incoming photo slides in the same direction as the message, over the previous photo, which stays visible until the transition completes; Reduce Motion fades the incoming photo over the previous one. The collection cycles in order without consecutive repeats when it contains multiple photos. Rotation is session state; the saved preference records only Colours/Photo mode. A restart begins at the first photo. Re-rendering, favouriting and opening Settings leave the current photo alone unless the displayed affirmation changes. Affirmations and tags remain independent of themes and photos.

Check portrait and landscape crops, long affirmations, accessibility text sizes and toolbar contrast for each added photograph.
