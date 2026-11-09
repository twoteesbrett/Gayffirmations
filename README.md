# Gayffirmations

Gayffirmations is a SwiftUI app for iPhone and iPad that brings queer affirmations into your day. Swipe through messages on the Today screen or set up daily reminders for the times you want them.

## Features

- **Affirmation library.** Browse the bundled collection, write your own messages, and organise them with favourites and tags. Add your name in Settings to personalise supported messages.
- **Daily reminders.** Create schedules with their own affirmation selections, time windows, and reminder counts. Space reminders evenly or group more of them toward the start or end of the window. Preview the delivery times before enabling a schedule.
- **Themes and sounds.** Choose from six visual themes, set a theme for each schedule, and adjust background images and text contrast. Use the system notification sound, choose one of five custom sounds, or turn sound off.

## Build and test

The app targets iOS and iPadOS 17.6 or later. Open `Gayffirmations.xcodeproj` in Xcode, select the shared **Gayffirmations** scheme, and run it on an iOS simulator.

Run the validation script from the repository root to build an unsigned Release app, check that it includes the privacy manifest, and run the Debug test suite.

```sh
bash scripts/validate.sh
```

The script defaults to an iPhone 18 Pro simulator on the latest installed runtime. Set `TEST_DESTINATION` to use a different installed simulator. The script prints the directory containing the build logs and test results.

## Privacy and credits

Affirmations, preferences, and your optional name are stored on your device. The app schedules reminders locally and does not use analytics or tracking.

The five custom notification sounds come from Mixkit.
