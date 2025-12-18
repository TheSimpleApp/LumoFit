#!/bin/bash

# Deploy to TestFlight Script
# This script builds the Flutter IPA and uploads it to TestFlight

set -e  # Exit on any error

echo "🚀 Starting TestFlight deployment..."
echo ""

# Navigate to project root
cd "$(dirname "$0")"

# Step 1: Build the IPA
echo "📦 Building IPA..."
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

echo ""
echo "✅ IPA built successfully!"
echo ""

# Step 2: Upload to TestFlight
echo "☁️  Uploading to TestFlight..."
cd ios
fastlane beta

echo ""
echo "🎉 Deployment complete!"

