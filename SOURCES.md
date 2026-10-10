# Asset sources

Sources and preparation details for bundled images and notification sounds.
App behaviour and development guidance are in [README.md](README.md).

## Images

Steel uses six user-supplied AI-generated images. Bundled JPEGs and PNGs preserve the supplied aspect ratios and resolution.

| Image | Bundled asset identifier |
| --- | --- |
| Strength | `steel-strength` |
| Release | `steel-release` |
| Curl | `steel-curl` |
| Deadlift | `steel-deadlift` |
| Squat | `steel-squat` |
| Pull-up | `steel-pull-up` |

Eden uses six user-supplied images, preserving their original resolution and aspect ratio.

| Image | Bundled asset identifier |
| --- | --- |
| Monstera | `eden-monstera` |
| Peace Lily | `eden-peace-lily` |
| Stream | `eden-stream` |
| Ferns | `eden-ferns` |
| Ivy | `eden-ivy` |
| Tropical Leaves | `eden-tropical-leaves` |

Eden retains colour; Steel renders in greyscale.

Each image has an individually configured crop focal point and dark overlay. Images are decorative backgrounds; the picker provides descriptive accessibility labels.

Disco uses six user-supplied AI-generated images, preserving their original resolution and aspect ratio.

| Image | Bundled asset identifier |
| --- | --- |
| Mirrorball | `disco-mirrorball` |
| Aviators | `disco-aviators` |
| Dance | `disco-dance` |
| Roller Skates | `disco-roller-skates` |
| Last Dance | `disco-last-dance` |
| Vinyl | `disco-vinyl` |

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

## Concrete

Concrete uses six user-supplied AI-generated images, preserving their original resolution and aspect ratio.

| Image | Bundled asset identifier |
| --- | --- |
| Fjord | `concrete-fjord` |
| Oculus | `concrete-oculus` |
| Sunlight | `concrete-sunlight` |
| Pillar | `concrete-pillar` |
| Ivy | `concrete-ivy` |
| Stairway | `concrete-stairway` |

## Out & About

Out & About uses six user-supplied AI-generated images, preserving their original resolution
and aspect ratio. Images rotate from morning through midday to evening.

| Image | Bundled asset identifier |
| --- | --- |
| Lakeside | `out-and-about-lakeside` |
| Market | `out-and-about-market` |
| Pool Club | `out-and-about-pool-club` |
| Park | `out-and-about-park` |
| Harbour | `out-and-about-harbour` |
| Carnival | `out-and-about-carnival` |

Bundled copies use `image.png`.
