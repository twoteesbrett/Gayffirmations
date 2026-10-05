# Asset sources

Sources and preparation details for bundled photos and notification sounds.
App behaviour and development guidance are in [README.md](README.md).

## Photos

Steel uses six user-supplied AI-generated images from `/Users/brett/Desktop/assets`. Bundled JPEGs and PNGs preserve the supplied aspect ratios and resolution.

| Photo | Original file | Source |
| --- | --- | --- |
| Strength | Monochrome Barbell Curl Portrait.png | User-supplied AI-generated image |
| Release | Monochrome Kettlebell Roar.png | User-supplied AI-generated image |
| Curl | Original filename not recorded | User-supplied AI-generated image |
| Deadlift | Original filename not recorded | User-supplied AI-generated image |
| Squat | ChatGPT Image Oct 4, 2026 at 01_02_33 PM.png | User-supplied AI-generated image |
| Pull-up | Monochrome Pull-Up in an Industrial Gym.png | User-supplied AI-generated image |

Nature uses six user-supplied Pexels photos from `/Users/brett/Desktop/assets`. Bundled JPEGs preserve their aspect ratios and are resized to a maximum dimension of 3,000 pixels to keep background decoding lightweight.

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

Disco’s Mirrorball uses the user-supplied `Neon Mirrorball Disco Glow.png` from `/Users/brett/Desktop/assets`, preserving its original resolution and aspect ratio.

Disco also includes Aviators (`disco-aviators`) and Neon Portrait
(`disco-portrait`). Their original filenames and source details have not yet
been recorded.

## Notification sounds

The user supplied five WAV files with Mixkit filenames from
`/Users/brett/Downloads`. Original filenames are retained below for provenance.
The originals remain outside the app; only optimized CAF files are bundled.

| Sound | Original filename | Duration | WAV bytes | CAF bytes |
| --- | --- | --- | --- | --- |
| Flute | mixkit-uplifting-flute-notification-2317.wav | 3.993 s | 704,360 | 93,733 |
| Marimba | mixkit-magic-marimba-2820.wav | 3.341 s | 589,586 | 78,506 |
| Choir | mixkit-choir-harp-bless-657.wav | 2.983 s | 526,314 | 70,108 |
| Harp | mixkit-relaxing-harp-sweep-2628.wav | 6.330 s | 1,116,740 | 148,507 |
| Ahem | mixkit-male-clearing-the-throat-2226.wav | 1.483 s | 262,196 | 34,877 |

The optimized files live in `Gayffirmations/Resources/Sounds`. The original
WAVs remain in the user's Downloads folder and are not copied into the app.
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
