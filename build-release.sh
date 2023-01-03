#!/bin/sh

set -e

echo "Running flutter clean"
flutter clean

#echo "=== Building release for iOS ==="
#flutter build ipa --release

#echo "We can run xcode to upload the build file. To do that, run the following command:"
#echo "open build/ios/archive/Runner.xcarchive"

#echo "\n\n\n"

echo "=== Building release for Android ==="
flutter build appbundle --release

echo "The bundle file is ready to upload to Google Play, run the following command:"
echo "open build/app/outputs/bundle/release"
