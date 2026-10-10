# Notification validation — 10 October 2026

## Automated checks completed

- Clean unsigned generic-iOS Release build passed, including privacy manifest packaging.
- All 206 tests passed on iPhone 18 Pro simulator / iOS 27.0.
- All 206 tests passed on physical iPhone 14 / iOS 27.0.1.
- The physical test app used `com.awkwardminds.validation.Gayffirmations`,
  separate from the regular app and its preferences.

The notification adapter tests inject a fake notification center while constructing
real `UNNotificationRequest`, `UNMutableNotificationContent`, and calendar trigger
objects. They verify authorization mapping and requested options; request identifiers,
title/body, exact hour/minute components and daily repetition; None/default and all
five exact custom sound mappings; invalid counts; removal; partial add failures and
retry; cancellation during add; and coordinator rollback through the real adapter.
These tests do not establish OS delivery, permission prompts, or audible playback.

Results from this session:

- Simulator: `/var/folders/kn/79j15h654qj6ydkjcv16xsth0000gn/T/Gayffirmations-validation.Yn49pp/Tests.xcresult`
- Physical device: `/private/tmp/Gayffirmations-device-contract-validation.xcresult`
- Physical test log: `/private/tmp/Gayffirmations-device-contract-tests.log`

## Manual device checks

The first attempt produced no observed alert while the phone was Home/locked.
On 10 October 2026, in-app inspection of the public notification-center APIs
confirmed authorized permission, enabled banners/lock-screen alerts/sound, and
disabled Scheduled Delivery. iOS recorded validation-app notifications delivered
at 22:20 and 22:24 Auckland time, matching the updated five-reminder schedule
between 22:15 and 22:25. The user confirmed Sleep Focus was active, consistent with
silenced presentation. After disabling Sleep Focus and scheduling one future
reminder, the user confirmed notification arrival with the expected text and sound
while Home/locked. This completes the basic device delivery check. Temporary
diagnostic source was removed after inspection.

- [x] Schedule one reminder a few minutes ahead, background or lock the device,
  and confirm notification arrival with the preview's text and expected sound.
- [x] Revoke permission in system Settings and return to the running app. Verify
  the blocked status and the ability to disable/delete individual routines.
- [x] Re-enable permission in system Settings and return without force-quitting.
  Confirm remaining routines resume at their next preview time without a new prompt.
- [x] Confirm delivery while the app is terminated.
- [x] Check every custom sound, Default, and None on-device.
- [x] Check custom affirmation, favorite, and theme persistence across termination.
- [ ] Check clean installation, customized legacy-content upgrade, and persistence
  across termination using disposable validation data.
- [x] Check largest accessibility text size on the iPhone across Home, library/editor,
  Settings, and schedules.
- [ ] Check long affirmation text, VoiceOver, Reduce Motion, and small-phone
  and iPad layouts.
- [ ] Validate a signed distribution archive and App Store privacy answers.

Record observations and dates when completing each check. A signed device test build
is a development build; it does not establish distribution archive validation.

On 11 October 2026, the user confirmed the Settings sheet displayed
"Blocked - permission off" after notification permission was revoked, and confirmed
schedule disabling/deletion worked. Re-enabling permission without closing the app
restored the schedules display. The user subsequently confirmed a future reminder
arrived after this permission transition, completing the recovery-delivery check.

On 11 October 2026, the user accidentally deleted the separate validation app,
installed their latest build on the iPhone, and confirmed a scheduled notification
still arrived after swiping that app away from the app switcher. This confirms
delivery while terminated for the user-installed latest build; its bundle identity
and build configuration were not independently inspected in this check.

On 11 October 2026, the user confirmed the sound checks passed and that a temporary
custom affirmation, a favorite, and a theme change persisted after swiping the app
away and reopening it. Clean-install and customized legacy-content upgrade checks
remain pending; this persistence check does not establish those migration paths.

On 11 October 2026, the user reported all inspected screens looked fine at the
largest accessibility text size on their iPhone. VoiceOver, Reduce Motion, long
affirmation text, and other device layouts remain unverified.
