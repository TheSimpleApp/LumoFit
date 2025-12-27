#!/bin/bash
set -e

echo "========================================"
echo "  LumoFit iOS Build with Auto-Versioning"
echo "========================================"
echo ""

# Navigate to ios folder
cd "$(dirname "$0")/../ios"

# Get latest build number from TestFlight and increment
echo "Fetching latest TestFlight build number..."
LATEST_BUILD=$(fastlane run latest_testflight_build_number 2>&1 | grep -E "^\d+$" | tail -1)

# Fallback: check current local build number if fastlane fails
if [ -z "$LATEST_BUILD" ]; then
    echo "Could not fetch from TestFlight, checking local build number..."
    LATEST_BUILD=$(agvtool what-version -terse)
fi

NEW_BUILD=$((LATEST_BUILD + 1))

echo ""
echo "Latest build: $LATEST_BUILD"
echo "New build number: $NEW_BUILD"
echo ""

# Update build number in Xcode project
echo "Updating build number to $NEW_BUILD..."
agvtool new-version -all $NEW_BUILD

# Go back to project root
cd ..

# Build IPA
echo ""
echo "Building IPA..."
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

echo ""
echo "========================================"
echo "  Build Complete!"
echo "========================================"
echo ""
echo "IPA Location: build/ios/ipa/LumoFit.ipa"
echo "Build Number: $NEW_BUILD"
echo "Version: 1.0.0"
echo ""
echo "Next steps:"
echo "  Option A - Fastlane: cd ios && fastlane beta"
echo "  Option B - Transporter: Drag build/ios/ipa/LumoFit.ipa to Transporter app"
echo ""
