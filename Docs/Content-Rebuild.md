# Content rebuild and multiple photos per theme

## Current baseline

The shipped catalogue now has one Neutral theme, no starter affirmations, no predefined tag presets, and no theme photos. Library editing, custom tags, favourites, selections, scheduling, persistence, and accessibility remain available.

On the next launch, a one-time content revision clears saved affirmations (including favourites and tags), the selected theme, source selections, and the old photo toggle. Reminder schedules remain saved; launch reconciliation removes reminders when there are no eligible affirmations. New content created after that launch is preserved. Before clearing preferences, the repository saves the old content in `gayffirmations.contentBeforeRebuild`. Removed bundled content is also backed up outside the project at `/private/tmp/gayffirmations-content-before-reset.zip`.

Retired theme identifiers decode as Neutral. Unknown or malformed saved data still reports an error. Retired identifiers are retained only for migration.

## Recommended content structure

Use a catalogue of theme definitions with stable IDs rather than growing Swift switches. A theme owns its name, description, light/dark palette, font design and weight, and an ordered array of photo IDs. Renaming a theme must not change its identity.

Each photo is a separate definition with a stable ID, asset name, accessibility description, source/credit, text and icon colour, overlay colour and opacity, and a focal point for cropping. Contrast belongs to the individual photo, not the theme's gradient. One photo can be reused by several themes without duplicating the asset.

Use portrait JPEGs around 1440 × 3120 where practical. Preserve originals separately. Validate the portrait and landscape crops and text contrast, including long affirmations, large text, and both toolbar icons.

Affirmations should have stable IDs, text, and explicit tag IDs. Tags should have stable IDs and editable display names; presets refer to tag IDs. This avoids a spelling change breaking filtering or favourites. Before adding a revised starter library, define how built-in entries and user-created entries coexist and how edits/favourites survive catalogue updates.

## Photo choices

Store background preferences per theme:

- **Colours:** use the theme gradient.
- **Photo:** select one photo from a thumbnail grid and keep it selected.
- **Daily photo:** select a different eligible photo each day, avoiding the previous photo when the theme has more than one.

Start with Colours and Photo; add Daily photo after selection and persistence are working. Do not add a running slideshow by default.

Persist the background mode, selected photo ID, and (for Daily photo) last photo ID and local calendar date. Save the photo choice, rather than relying on the array index or a hash that may change. Switching themes restores that theme's previous choice. A removed photo falls back to an available photo; a theme with no photos uses its gradient. None of these changes should reset the user's affirmation selection.

## Rendering and stability

Resolve the photo once at the screen/root level and pass the same photo definition to the background, affirmation, hamburger, heart, and preview. Never pick a random photo inside `body` or the existing minute-based TimelineView.

For Daily photo, check the date on app activation and local midnight. Keep the photo stable across scrolling, swiping affirmations, saving favourites, and opening Settings. Respect reduced motion if transitions are introduced.

## Implementation order

1. Agree on the new theme list, palettes, typography, affirmation voice, and tag vocabulary.
2. Introduce catalogue definitions and stable IDs, with migration for existing custom string tags.
3. Add photos and their individual contrast/crop settings; validate the assets and metadata.
4. Add the per-theme Colours/Photo picker and persistence, using one shared resolved photo.
5. Add Daily photo with tests for no repeats, restart stability, midnight/time-zone changes, and missing/removed photos.

Required checks include fresh install/empty states, retired theme migration, content reset running only once, preservation of newly added content, saved theme/photo choices, missing assets, and portrait/landscape readability.
