# Asset sources

Sources and preparation details for bundled photos and notification sounds.
App behaviour and development guidance are in [README.md](README.md).

## Photos

Steel uses six user-supplied AI-generated images from `/Users/brett/Desktop/gayffirmations-assets`. Bundled JPEGs and PNGs preserve the supplied aspect ratios and resolution.

| Photo | Source file | Source |
| --- | --- | --- |
| Strength | steel-strength.png | User-supplied AI-generated image |
| Release | steel-release.png | User-supplied AI-generated image |
| Curl | steel-curl.png | User-supplied AI-generated image |
| Deadlift | steel-deadlift.png | User-supplied AI-generated image |
| Squat | steel-squat.png | User-supplied AI-generated image |
| Pull-up | steel-pull-up.png | User-supplied AI-generated image |

Nature uses six user-supplied Pexels photos from `/Users/brett/Desktop/gayffirmations-assets`. Bundled JPEGs preserve their aspect ratios and are resized to a maximum dimension of 3,000 pixels to keep background decoding lightweight.

| Photo | Source filename identifier | Original file / source ID |
| --- | --- | --- |
| Canyon | austin-sullivan | pexels-austin-sullivan-48171954-13386963.jpg / 13386963 |
| Meadow | koolshooters | pexels-koolshooters-8530929.jpg / 8530929 |
| Forest | sargonsama | pexels-sargonsama-38440480.jpg / 38440480 |
| Beach | ramesh-chaudhary | pexels-ramesh-chaudhary-39043125-30519147.jpg / 30519147 |
| River | baro | pexels-baro-405354470-14942582.jpg / 14942582 |
| Waterfall | angshupurkait | pexels-angshupurkait-8056705.jpg / 8056705 |

Nature retains colour; Steel renders in greyscale.

Each photo has an individually configured crop focal point and dark overlay. Photos are decorative backgrounds; the picker provides descriptive accessibility labels.

Disco uses six user-supplied AI-generated images from `/Users/brett/Desktop/gayffirmations-assets`, preserving their original resolution and aspect ratio.

| Photo | Source file | Bundled asset identifier |
| --- | --- | --- |
| Mirrorball | disco-mirrorball.png | `disco-mirrorball` |
| Aviators | disco-aviators.png | `disco-aviators` |
| Dance | disco-dance.png | `disco-dance` |
| Roller Skates | disco-roller-skates.jpg | `disco-roller-skates` |
| Last Dance | disco-last-dance.png | `disco-last-dance` |
| Vinyl | disco-vinyl.png | `disco-vinyl` |

## AI-generated source filenames

On 6 October 2026, the AI-generated files in `/Users/brett/Desktop/gayffirmations-assets` were renamed to lowercase, hyphenated names. Existing theme photos match the app's asset identifiers. File contents and extensions were preserved; files starting with `pexels` or `mixkit` were left unchanged.

| Previous filename | Current filename |
| --- | --- |
| Monochrome Barbell Curl Portrait.png | steel-strength.png |
| Monochrome Kettlebell Roar.png | steel-release.png |
| Cinematic Monochrome Dumbbell Curl.png | steel-curl.png |
| Low-Key Deadlift Power.png | steel-deadlift.png |
| ChatGPT Image Oct 4, 2026 at 01_02_33 PM.png | steel-squat.png |
| Monochrome Pull-Up in an Industrial Gym.png | steel-pull-up.png |
| Neon Mirrorball Disco Glow.png | disco-mirrorball.png |
| Neon Disco Aviators on Marble.png | disco-aviators.png |
| Neon-lit portrait with vibrant bokeh.png | disco-portrait.png |
| ChatGPT Image 6 Oct 2026, 17_46_54.png | disco-dancefloor-portrait.png |
| ChatGPT Image 6 Oct 2026, 17_37_42.jpg | disco-roller-skates.jpg |
| Gayffirmations app icon.png | gayffirmations-app-icon.png |

The former `disco-portrait` and `disco-dancefloor-portrait` assets are no longer bundled in the app. `disco-dance.png` replaces the Dancefloor portrait in the Disco rotation. `gayffirmations-app-icon.png` is the AI-generated icon source; the app bundles its prepared icon as `AppIcon.appiconset/AppIcon.png`.

The app reads bundled copies from `Gayffirmations/Assets.xcassets`, not the Desktop source folder. These source renames require no Swift, asset catalog, or saved-selection changes. When renaming a bundled image file, update its `Contents.json`; when changing an asset identifier, also update code references and account for persisted selections using the old identifier.

## Notification sounds

The user supplied five WAV files with Mixkit filenames from
`/Users/brett/Desktop/gayffirmations-assets`. Original filenames are retained below for provenance.
The originals remain outside the app; only optimized CAF files are bundled.

| Sound | Original filename | Duration | WAV bytes | CAF bytes |
| --- | --- | --- | --- | --- |
| Flute | mixkit-uplifting-flute-notification-2317.wav | 3.993 s | 704,360 | 93,733 |
| Marimba | mixkit-magic-marimba-2820.wav | 3.341 s | 589,586 | 78,506 |
| Choir | mixkit-choir-harp-bless-657.wav | 2.983 s | 526,314 | 70,108 |
| Harp | mixkit-relaxing-harp-sweep-2628.wav | 6.330 s | 1,116,740 | 148,507 |
| Ahem | mixkit-male-clearing-the-throat-2226.wav | 1.483 s | 262,196 | 34,877 |

The optimized files live in `Gayffirmations/Resources/Sounds`. The original
WAVs are available in the user's Desktop assets folder and are not copied into the app.
Total asset size is 425,731 bytes, about 87% smaller than the originals
(3,199,196 bytes).


Audio was converted from stereo 16-bit PCM WAV to mono IMA4 CAF at the
original 44,100 Hz sample rate. Full duration is preserved, with no trimming
or loudness adjustment.

```sh
ffmpeg -i input.wav -ac 1 -c:a adpcm_ima_qt output.caf
```

| Display name | Bundled filename / saved identifier |
| --- | --- |
| Flute | `uplifting-flute.caf` / `uplifting-flute` |
| Marimba | `magic-marimba.caf` / `magic-marimba` |
| Choir | `choir-harp-bless.caf` / `choir-harp-bless` |
| Harp | `relaxing-harp-sweep.caf` / `relaxing-harp-sweep` |
| Ahem | `clearing-the-throat.caf` / `clearing-the-throat` |

Codec, channel count, duration, and file size were checked with ffprobe.
All five files passed full ffmpeg decode checks. Simulator tests verify
AVAudioPlayer decoding from the app bundle. Listening review and notification
playback checks on an iPhone remain in [TODO.md](TODO.md).

Apple references: [custom notification sounds](https://developer.apple.com/documentation/usernotifications/unnotificationsound)
and [system alert playback limitations](https://developer.apple.com/documentation/audiotoolbox/audioservicesplayalertsound(_:)).

## Concrete

Concrete uses six user-supplied AI-generated images, preserving their original resolution and aspect ratio. Source images are in `/Users/brett/Desktop/gayffirmations-assets`.

| Photo | Source file | Bundled asset identifier |
| --- | --- | --- |
| Fjord | concrete-fjord.png | `concrete-fjord` |
| Oculus | concrete-oculus.png | `concrete-oculus` |
| Sunlight | concrete-sunlight.png | `concrete-sunlight` |
| Pillar | concrete-pillar.png | `concrete-pillar` |
| Ivy | concrete-ivy.png | `concrete-ivy` |
| Stairway | concrete-stairway.png | `concrete-stairway` |
