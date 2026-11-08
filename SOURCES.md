# Asset sources

Sources and preparation details for bundled images and notification sounds.
App behaviour and development guidance are in [README.md](README.md).

## Images

Steel uses nine user-supplied AI-generated images. Bundled JPEGs and PNGs preserve the supplied aspect ratios and resolution.

| Image | Bundled asset identifier |
| --- | --- |
| Dramatic Monochrome Barbell Curl Portrait | `steel-strength` |
| Release | `steel-release` |
| Monochrome Gym Curl Portrait | `steel-curl` |
| High-Contrast Deadlift in the Gym | `steel-deadlift` |
| Dramatic Barbell Squat in Monochrome | `steel-squat` |
| Monochrome Pull-Up Muscle Definition | `steel-pull-up` |
| Monochrome Bench Press Strength | `steel-bench-press` |
| Monochrome Dumbbell Lateral Raise | `steel-lateral-raise` |
| Monochrome Dumbbell Lunge in the Gym | `steel-lunge` |

The three additional images were supplied from Desktop and copied into Assets and the app asset catalogue without resizing.

Out & About retains colour; Steel renders in greyscale. Each image has a crop focal point and dark overlay.

## App icon

The app uses a user-supplied AI-generated icon, bundled as
`AppIcon.appiconset/AppIcon.png`.

The app reads bundled images from `Gayffirmations/Assets.xcassets`.

## Notification sounds

The five notification sounds are from Mixkit. Only optimized CAF files are bundled.

| Sound | Duration | WAV bytes | CAF bytes |
| --- | --- | --- | --- |
| Flute | 3.993 s | 704,360 | 93,733 |
| Marimba | 3.341 s | 589,586 | 78,506 |
| Choir | 2.983 s | 526,314 | 70,108 |
| Harp | 6.330 s | 1,116,740 | 148,507 |
| Ahem | 1.483 s | 262,196 | 34,877 |

The optimized files live in `Gayffirmations/Resources/Sounds`.
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

## Out & About

Out & About uses nine user-supplied AI-generated images imported from Desktop/assets/out and about.
Renamed source copies in Assets and bundled PNGs preserve the originals' resolution and aspect ratio.
The rotation progresses from daylight through sunset and twilight to moonlight.

| Image | Bundled asset identifier |
| --- | --- |
| Lakeside Café | `out-and-about-lakeside-cafe` |
| Market | `out-and-about-market` |
| Greenhouse Garden | `out-and-about-greenhouse-garden` |
| Beach | `out-and-about-beach` |
| Villa Pool | `out-and-about-villa-pool` |
| Waterfall | `out-and-about-waterfall` |
| Thermal Baths | `out-and-about-thermal-baths` |
| Twilight Dinner | `out-and-about-twilight-dinner` |
| Moonlit Piazza | `out-and-about-moonlit-piazza` |

## Together

Together uses nine user-supplied AI-generated images imported from Desktop/assets/together.
Renamed source copies in Assets and bundled PNGs preserve the original files, resolution and aspect ratio.
The ordered rotation follows the accompanying life-stage brief, from first love around 1970 to companionship around 2012. Dates and stages are narrative interpretations of the images and brief.

| Order | Original image | Bundled asset identifier |
| --- | --- | --- |
| 1 | Vintage Pickup by the Lake | `together-pickup-romance` |
| 2 | Vintage Beachside Camping Companions | `together-beach-camping` |
| 3 | Retro Shoreline Companions | `together-sunny-shore` |
| 4 | Cosy Vintage Living Room Reading | `together-couch-reading` |
| 5 | Loving Retro Kitchen Tomato Prep | `together-kitchen` |
| 6 | Cyclists Consulting a Roadside Map | `together-cycling` |
| 7 | Hikers Overlooking a Mountain Lake | `together-mountain-break` |
| 8 | Warm Park Café Conversation | `together-coffee` |
| 9 | Sunset Shoreline Portrait of Two Friends | `together-coastal-companionship` |

## Ages

Ages uses nine user-supplied images imported from Desktop/assets/ages.
The renamed copies in Assets and the asset catalogue preserve the original PNG files.

| Original image | Bundled asset identifier |
| --- | --- |
| Vintage Harbour Bus Stop | `ages-harbour-bus-stop` |
| Studying at University | `ages-university` |
| A Quiet Moment of Support | `ages-quiet-support` |
| Seaside Campfire at Sunset | `ages-seaside-campfire` |
| Warm 1980s Office Collaboration | `ages-office` |
| Support Along the Wet Coast | `ages-coastal-walk` |
| Warm Vintage Kitchen Cooking | `ages-kitchen` |
| Nostalgic Memories Among Moving Boxes | `ages-moving-boxes` |
| Sunny Garden Carrot Harvest | `ages-garden-harvest` |
## Gay Wonderland

Gay Wonderland uses nine user-supplied PNGs from `Desktop/assets/gay wonderland`.
The copies in `Assets` and the asset catalogue preserve the original PNG files.

| Rotation | Original filename (without .png) | Bundled asset identifier |
| --- | --- | --- |
| 1 | Surreal Pink Couture Runway | `gay-wonderland-pink-couture-runway` |
| 2 | Velvet Rebellion_ The Red Phone Shrug | `gay-wonderland-red-telephone-stage` |
| 3 | gay-wonderland-coral-paradise | `gay-wonderland-coral-paradise` |
| 4 | Focused Lemon Factory Worker | `gay-wonderland-lemon-factory` |
| 5 | Surreal Emerald Apple Dreamscape | `gay-wonderland-emerald-apple` |
| 6 | Surreal Iceberg Ironing Dreamscape | `gay-wonderland-iceberg-ironing` |
| 7 | Dreamy Carousel Rider in Purple Fantasy | `gay-wonderland-indigo-zebra-carnival` |
| 8 | Retro Surreal Banana Vortex Collage | `gay-wonderland-lavender-banana` |
| 9 | Clouds, Chrome, and Pearls | `gay-wonderland-clouds-chrome-and-pearls` |

## Shit Happens

Shit Happens uses nine user-supplied PNGs. Poolside Chair came from `Desktop/assets` and the other eight came from `Desktop/assets/shit happens`.
The renamed copies in `Assets` and the asset catalogue preserve the original PNG files.

| Rotation | Original image | Bundled asset identifier |
| --- | --- | --- |
| 1 | Mirror Check Before the Big Day | `shit-happens-mirror-check` |
| 2 | Burnt Toast Kitchen Mishap | `shit-happens-burnt-toast` |
| 3 | Café Mishap and Laughter | `shit-happens-cafe-laughter` |
| 4 | Laundromat Mishap with Rainbow Tank Top | `shit-happens-laundromat` |
| 5 | Garden Party Laughter Under String Lights | `shit-happens-matching-shirts` |
| 6 | Coffee Spill at the Outdoor Café | `shit-happens-coffee-spill` |
| 7 | Muddy Trail Companions and a Happy Dog | `shit-happens-muddy-trail` |
| 8 | Poolside Chair Mishap | `shit-happens-poolside-chair` |
| 9 | Sheepish Downward Dog in the Park | `shit-happens-park-yoga` |
