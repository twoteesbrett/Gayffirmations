#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."
destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 18 Pro,OS=latest}"
validation_dir="$(mktemp -d "${TMPDIR:-/tmp}/Gayffirmations-validation.XXXXXX")"
echo "Validation results: $validation_dir"

xcodebuild -project Gayffirmations.xcodeproj -scheme Gayffirmations \
    -configuration Release -destination 'generic/platform=iOS' \
    -derivedDataPath "$validation_dir/Release" \
    CODE_SIGNING_ALLOWED=NO clean build \
    > "$validation_dir/release.log" 2>&1 || {
        tail -n 80 "$validation_dir/release.log"
        exit 1
    }
echo "Release build passed."

manifest="$validation_dir/Release/Build/Products/Release-iphoneos/Gayffirmations.app/PrivacyInfo.xcprivacy"
plutil -lint "$manifest"
cmp Gayffirmations/PrivacyInfo.xcprivacy "$manifest"
echo "Privacy manifest is included in the Release app."

xcodebuild -project Gayffirmations.xcodeproj -scheme Gayffirmations \
    -configuration Debug -destination "$destination" \
    -derivedDataPath "$validation_dir/Debug" \
    -resultBundlePath "$validation_dir/Tests.xcresult" \
    CODE_SIGNING_ALLOWED=NO test \
    > "$validation_dir/tests.log" 2>&1 || {
        tail -n 80 "$validation_dir/tests.log"
        exit 1
    }
echo "Debug tests passed."
