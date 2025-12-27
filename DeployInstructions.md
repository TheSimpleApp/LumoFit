# LumoFit Deployment Instructions

Complete guide for deploying LumoFit to Web (Firebase), iOS (TestFlight), and App Store.

---

## Version Strategy

- **App Version:** `1.0.0` (defined in `pubspec.yaml`)
- **Build Number:** Auto-incremented based on latest TestFlight/App Store build
- Fastlane automatically fetches the latest build number and increments it

---

## Quick Reference

| Platform | Command | Output |
|----------|---------|--------|
| Web | `flutter build web --release && firebase deploy --only hosting` | Firebase Hosting |
| iOS (Auto Everything) | `cd ios && fastlane auto_deploy` | TestFlight (auto-commit, auto-merge, auto-build) |
| iOS (Quick Deploy) | `cd ios && fastlane beta_with_build` | TestFlight (auto-build only) |
| iOS (Manual + Transporter) | See [Manual IPA Build](#option-2-manual-ipa-build--transporter) | Drag to Transporter |

---

## Web Deployment (Firebase Hosting)

### Prerequisites
- Firebase CLI installed: `npm install -g firebase-tools`
- Logged in: `firebase login`

### Deploy to Web

```bash
# Build Flutter web app
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

Your site will be live at: `https://your-project.web.app`

### One-Liner
```bash
flutter build web --release && firebase deploy --only hosting
```

---

## iOS Deployment

### Prerequisites
- Xcode installed with valid signing certificates
- Fastlane installed: `gem install fastlane` or `brew install fastlane`
- Apple Developer account configured in `ios/fastlane/Appfile`

### Option 1: Fastlane (Recommended)

Fastlane handles auto-versioning, auto-building, and auto-changelog generation.

#### 🚀 ULTIMATE Auto-Deploy (Zero Manual Steps)

The ultimate deployment: auto-commit, auto-merge, auto-build, auto-deploy:
```bash
cd ios
fastlane auto_deploy
```

This will:
1. **Auto-commit** all your changes with generated message
2. **Auto-pull** latest changes from remote main
3. **Auto-resolve** any merge conflicts (keeps your local changes)
4. **Auto-push** to remote main
5. **Auto-increment** build number
6. **Auto-generate** changelog from commits
7. **Auto-build** fresh IPA with all changes
8. **Auto-upload** to TestFlight

**Literally zero manual steps!** Just code and run one command.

#### 🏃 Quick Deploy (Manual Git)

Deploy with auto-build, auto-versioning, and auto-changelog (you handle git manually):
```bash
cd ios
fastlane beta_with_build
```

This will:
1. Fetch latest TestFlight build number
2. Increment to next build number automatically
3. Generate changelog from git commits since last tag
4. Build fresh IPA with all your latest changes
5. Upload to TestFlight with "What's New" description

#### Manual Build + Upload (Alternative)

**Step 1:** Build the IPA manually
```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

**Step 2:** Upload to TestFlight with auto-versioning
```bash
cd ios
fastlane beta
```

#### App Store Release
```bash
cd ios
fastlane release
```

### Option 2: Manual IPA Build + Transporter

If you prefer using Transporter app for uploads:

**Step 1:** Get current build number and increment manually

Check current TestFlight build number in App Store Connect, then increment.

**Step 2:** Update build number in Xcode
```bash
cd ios
# Replace BUILD_NUMBER with next number (e.g., 18, 19, etc.)
agvtool new-version -all BUILD_NUMBER
```

Or use fastlane to just increment (without uploading):
```bash
cd ios
fastlane run increment_build_number xcodeproj:Runner.xcodeproj
```

**Step 3:** Build the IPA
```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

**Step 4:** Find your IPA
```
build/ios/ipa/LumoFit.ipa
```

**Step 5:** Drag and drop into Transporter app

1. Open Transporter on your Mac
2. Drag `LumoFit.ipa` into the window
3. Click "Deliver"

### Auto-Versioning Script

Create this script for easy manual builds with auto-versioning:

**`scripts/build_ios.sh`**
```bash
#!/bin/bash
set -e

echo "Building iOS IPA with auto-versioned build number..."

# Navigate to ios folder
cd ios

# Get latest build number from TestFlight and increment
# This requires fastlane to be set up
LATEST_BUILD=$(fastlane run latest_testflight_build_number 2>/dev/null | grep "Result:" | awk '{print $2}')
NEW_BUILD=$((LATEST_BUILD + 1))

echo "Latest TestFlight build: $LATEST_BUILD"
echo "New build number: $NEW_BUILD"

# Update build number
agvtool new-version -all $NEW_BUILD

# Go back to project root
cd ..

# Build IPA
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

echo ""
echo "IPA built successfully!"
echo "Location: build/ios/ipa/LumoFit.ipa"
echo "Build number: $NEW_BUILD"
echo ""
echo "Next steps:"
echo "  - Upload via Fastlane: cd ios && fastlane beta"
echo "  - Or drag to Transporter: build/ios/ipa/LumoFit.ipa"
```

Make it executable:
```bash
chmod +x scripts/build_ios.sh
```

---

## Environment Variables

### Required for Builds

The dart-defines are embedded in the Fastfile, but for manual builds:

```bash
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist
```

Note: Supabase and API keys are configured via `lib/services/` and environment.

### Fastlane Authentication

**Automatic (Already Configured):**
Your Apple session cookies are auto-loaded from `~/.zshrc` - no manual export needed!

Just open a new terminal and run:
```bash
cd ios && fastlane beta_with_build
```

**For CI/CD (Optional):**
Set these environment variables for automated builds:

```bash
export APP_STORE_CONNECT_API_KEY_KEY_ID="your_key_id"
export APP_STORE_CONNECT_API_KEY_ISSUER_ID="your_issuer_id"
export APP_STORE_CONNECT_API_KEY_KEY="your_base64_encoded_key"
```

### Auto-Generated Changelogs

Fastlane automatically generates TestFlight "What's New" descriptions from your git commits:

**How it works:**

- Uses commits since last git tag (e.g., `v1.0.0`)
- If no tags exist, uses last 10 commits
- Formats as bullet list in TestFlight

**Best Practice - Use Git Tags:**
```bash
# After a major release, tag it
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0

# Now future builds will show commits since v1.0.0
# Make changes, commit them
git commit -m "feat: Add dark mode toggle"
git commit -m "fix: Resolve GPS accuracy issue"

# Deploy - changelog will show both commits
cd ios && fastlane beta_with_build
```

**Example TestFlight Description:**

```text
What's New:
• feat: Add dark mode toggle
• fix: Resolve GPS accuracy issue
• chore: Update dependencies
```

---

## Current Configuration

### App Details
- **App Name:** LumoFit
- **Bundle ID:** `com.simple.LumoFit`
- **Version:** 1.0.0
- **Apple Team ID:** 2QJTN3CT3K

### Fastlane Setup
- Location: `ios/fastlane/`
- Appfile: Contains Apple ID and team configuration
- Fastfile: Contains `beta`, `beta_with_build`, and `release` lanes

### Firebase Setup
- Config: `firebase.json`
- Public directory: `build/web`
- SPA rewrites enabled

---

## Deployment Checklist

### Before Each Release

- [ ] Test the app thoroughly
- [ ] Update version in `pubspec.yaml` if needed (major/minor releases)
- [ ] Build number auto-increments (no action needed)
- [ ] Run `flutter clean` if experiencing build issues

### Web Release
- [ ] `flutter build web --release`
- [ ] `firebase deploy --only hosting`
- [ ] Verify at https://your-project.web.app

### iOS Release
- [ ] Ensure signing certificates are valid
- [ ] Build IPA: `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist`
- [ ] Upload: `cd ios && fastlane beta` OR drag to Transporter
- [ ] Verify in TestFlight

---

## Troubleshooting

### iOS Build Fails
```bash
# Clean everything
flutter clean
cd ios && rm -rf Pods Podfile.lock && pod install
cd ..
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

### Fastlane Authentication Issues
- Ensure Apple ID is correct in `ios/fastlane/Appfile`
- Try logging in again: `fastlane spaceauth -u dotson817@gmail.com`
- Or set up App Store Connect API key for automated auth

### Build Number Conflicts
If TestFlight rejects due to duplicate build number:
```bash
cd ios
agvtool new-version -all HIGHER_NUMBER
```

### Web CORS Issues
Ensure your domain is allowed in Supabase project settings.

---

## Quick Commands Summary

```bash
# Web
flutter build web --release && firebase deploy --only hosting

# iOS - Full flow with Fastlane
cd ios && fastlane beta

# iOS - Just build IPA (for Transporter)
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

# Check current build number
cd ios && agvtool what-version

# Increment build number manually
cd ios && agvtool new-version -all NEW_NUMBER
```
