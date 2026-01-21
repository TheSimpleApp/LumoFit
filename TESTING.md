# TESTING.md - Test Credentials & Automation Guide

> **Purpose:** Test credentials, flows, and automation scripts for Claude Code
> **Mode:** Autonomous with `--dangerously-skip-permissions`
> **Last Updated:** January 2026

---

## 🔑 Test Credentials

### Primary Test Account
```
Email:    test@example.com
Password: Test123
```

### When to Use
- All authentication testing
- End-to-end flow verification
- Feature testing
- Browser automation
- Screenshot verification

### Account Setup
If the test account doesn't exist, create it:
1. Launch app: `flutter run -d "iPhone 15 Pro"`
2. Tap "Sign Up"
3. Enter email: `test@example.com`
4. Enter password: `Test123`
5. Complete signup

---

## 🧪 Test Flows

### 1. Authentication Flow

```bash
# Test: Login with existing account
1. Launch app
2. Tap "Login"
3. Enter: test@example.com
4. Enter: Test123
5. Tap "Sign In"
6. VERIFY: Lands on Home screen
7. VERIFY: User name shows in Profile
```

```bash
# Test: Logout and re-login
1. Go to Profile tab
2. Tap logout/settings
3. Confirm logout
4. VERIFY: Returns to Login screen
5. Login again with test credentials
6. VERIFY: All user data persists
```

### 2. Map Tab Flow

```bash
# Test: Map loads correctly
1. Login with test account
2. Tap "Map" tab
3. VERIFY: Map renders
4. VERIFY: User location dot visible (or Cairo default)
5. VERIFY: Markers load for nearby places
```

```bash
# Test: Filter functionality
1. On Map screen
2. Tap "Gyms" filter chip
3. VERIFY: Only gym markers visible
4. Tap "Food" filter chip
5. VERIFY: Only food markers visible
6. Tap "All" or clear filters
7. VERIFY: All markers visible
```

```bash
# Test: Place preview
1. On Map screen
2. Tap any marker
3. VERIFY: Preview card slides up
4. VERIFY: Shows place name, type, distance
5. Tap preview card
6. VERIFY: Opens Place Detail screen
```

### 3. Discover Tab Flow

```bash
# Test: Discover loads
1. Tap "Discover" tab
2. VERIFY: Places list loads
3. VERIFY: Categories shown (Gyms, Food, Trails, Events)
4. Scroll down
5. VERIFY: More places load (pagination)
```

```bash
# Test: Category filtering
1. On Discover screen
2. Tap "Gyms" category
3. VERIFY: Only gyms displayed
4. Tap "Events" category
5. VERIFY: Only events displayed
```

```bash
# Test: Place Detail
1. Tap any place card
2. VERIFY: Place Detail screen opens
3. VERIFY: Shows name, address, rating
4. VERIFY: Action buttons work (Directions, Call, Save)
```

### 4. Save Flow

```bash
# Test: Save a place
1. Open any Place Detail
2. Tap "Save" button
3. VERIFY: Save confirmed (snackbar/toast)
4. Go to Profile tab
5. Tap "Saved Places"
6. VERIFY: Saved place appears in list
```

```bash
# Test: Unsave a place
1. Go to saved place detail
2. Tap "Unsave" or "Remove"
3. VERIFY: Removed from saved list
```

### 5. Events Flow

```bash
# Test: Events display
1. On Discover tab
2. Tap "Events" category
3. VERIFY: Events list loads
4. VERIFY: Shows event name, date, location
```

```bash
# Test: Event Detail
1. Tap any event
2. VERIFY: Event Detail screen opens
3. VERIFY: Shows full event info
4. VERIFY: Registration link works (if present)
```

### 6. Profile Flow

```bash
# Test: Profile displays
1. Tap Profile tab
2. VERIFY: User email shows
3. VERIFY: Stats visible (places visited, etc.)
4. VERIFY: Saved places section visible
```

---

## 🤖 Automated Test Commands

### Static Analysis
```bash
# Run after every code change
dart analyze lib/

# Expected output: "No issues found!"
# If errors: Fix them before proceeding
```

### Format Check
```bash
# Check formatting
dart format --set-exit-if-changed lib/

# Fix formatting
dart format lib/
```

### Unit Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Build Verification
```bash
# iOS build (no codesign for quick check)
flutter build ios --no-codesign

# Android build
flutter build apk --debug

# Full iOS release build
flutter build ipa
```

---

## 📱 Device Testing

### List Available Devices
```bash
flutter devices
```

### Run on Specific Device
```bash
# iOS Simulator
flutter run -d "iPhone 15 Pro"

# Any available iOS simulator
flutter run -d iphone

# Android emulator
flutter run -d emulator-5554

# Chrome (web)
flutter run -d chrome
```

### Hot Reload / Restart
```bash
# While app is running:
# r = hot reload (preserves state)
# R = hot restart (resets state)
# q = quit
```

---

## 🔄 Feedback Loop Script

Use this script for each task:

```bash
#!/bin/bash
# feedback_loop.sh - Run after every change

echo "=== Step 1: Analyze ==="
dart analyze lib/
if [ $? -ne 0 ]; then
    echo "❌ Analyzer found issues. Fix them first."
    exit 1
fi

echo "=== Step 2: Format ==="
dart format lib/

echo "=== Step 3: Build Check ==="
flutter build ios --no-codesign
if [ $? -ne 0 ]; then
    echo "❌ Build failed. Fix errors."
    exit 1
fi

echo "=== Step 4: Run Tests ==="
flutter test
if [ $? -ne 0 ]; then
    echo "⚠️ Some tests failed. Review output."
fi

echo "✅ All checks passed!"
echo "Now run: flutter run -d 'iPhone 15 Pro'"
```

---

## 🎭 Marionette App Testing

Marionette allows Claude to interact with your running Flutter app directly.

### Setup
1. Run `/setup-marionette` to install Marionette (one-time setup)
2. Launch app on any platform:
   ```bash
   # Windows Desktop
   flutter run -d windows

   # iOS Simulator (macOS only)
   flutter run -d "iPhone 15 Pro"

   # Android Emulator
   flutter run -d emulator
   ```
3. Copy the **VM Service URL** from console output:
   ```
   A Dart VM Service on Windows is available at: ws://127.0.0.1:XXXXX/XXXXX=/ws
   ```

### Using Marionette

**Take screenshots:**
```
"Take a screenshot of the current screen"
```

**Find elements:**
```
"Show me all buttons on this screen"
"Find the login email field"
```

**Interact with UI:**
```
"Tap the login button"
"Enter test@example.com in the email field"
"Scroll down on the discover screen"
```

**Test flows:**
```
"Test the login flow with test credentials"
"Navigate to the map tab and take a screenshot"
"Find and tap the save button"
```

**Automated analysis:**
```
/analyze-app
```
Then provide the VM service URL when prompted.

### Test Credentials for Marionette
Use these when testing authentication:
- Email: `test@example.com`
- Password: `Test123`

### Platform Notes
- **Windows Desktop**: Best performance, native experience
- **iOS Simulator**: Requires macOS
- **Web**: Limited Marionette support
- **VM Service URL changes** each time you restart the app

## 🌐 Browser Automation Testing

Claude Code can use browser automation to test web-based flows:

### Supabase Dashboard Check
```
URL: https://supabase.com/dashboard
Action: Verify Edge Functions deployed
Action: Check database tables
Action: Review authentication logs
```

### TestFlight Status
```
URL: https://appstoreconnect.apple.com
Action: Check build status
Action: Verify public link enabled
```

### App Preview (if web enabled)
```
Action: Run flutter run -d chrome
Action: Navigate through all tabs
Action: Take screenshots for verification
```

---

## 🐛 Debug Commands

### Flutter Logs
```bash
# View device logs
flutter logs

# Run with verbose output
flutter run --verbose
```

### Supabase Logs
```bash
# Check Edge Function logs (via dashboard or CLI)
supabase functions logs egypt_fitness_guide
```

### Clear App Data
```bash
# Clean Flutter build
flutter clean

# Reinstall dependencies
flutter pub get

# Reset iOS simulator
xcrun simctl erase all
```

---

## ✅ Test Checklist

Before marking any feature complete:

- [ ] `dart analyze lib/` shows "No issues found!"
- [ ] `dart format lib/` runs without changes
- [ ] App launches without crash
- [ ] Feature works on iOS simulator
- [ ] Login with test credentials works
- [ ] No console errors during feature use
- [ ] UI looks correct (visual check)
- [ ] Edge cases handled (empty states, errors)

---

## 📊 Test Coverage Goals

| Area | Coverage Target |
|------|-----------------|
| Auth flows | 100% manual test |
| Map tab | 100% manual test |
| Discover tab | 100% manual test |
| Save flow | 100% manual test |
| Profile | 100% manual test |
| Unit tests | Run existing, fix failures |

---

## 🚨 Common Issues & Fixes

### "No connected devices"
```bash
# Check devices
flutter devices

# Start iOS simulator
open -a Simulator

# Or specify simulator
xcrun simctl boot "iPhone 15 Pro"
```

### "Supabase auth error"
- Verify Supabase URL and anon key in config
- Check if test account exists
- Try creating new test account

### "Google Maps not loading"
- Verify API key in iOS/Android config
- Check API key restrictions in Google Cloud Console
- Ensure Maps SDK enabled for project

### "Build failed"
```bash
# Clean and retry
flutter clean
flutter pub get
flutter run
```

### "Marionette MCP not recognized" (Windows)

**Error:** `'marionette_mcp' is not recognized as an internal or external command`

**Root Cause:** Marionette MCP is a Dart package (not npm). On Windows, Dart global executables are `.bat` files that need `cmd /c` to run.

**Fix:** Update MCP config to use proper Windows invocation:

**WRONG:**
```json
{
  "marionette": {
    "command": "marionette_mcp",
    "args": []
  }
}
```

**CORRECT:**
```json
{
  "marionette": {
    "command": "cmd",
    "args": ["/c", "marionette_mcp"]
  }
}
```

**Config file locations:**
- Cursor: `~/.cursor/mcp.json`
- Claude Desktop: `%APPDATA%\Claude\claude_desktop_config.json`
- Claude Code: `~/.config/claude-code/mcp.json`

**Verify installation:**
```bash
# Check Marionette is installed
dart pub global activate marionette_mcp

# Test it works
cmd /c "marionette_mcp --version"
# Expected: marionette_mcp version: 0.2.4
```

**See:** `.claude/analysis/marionette-mcp-setup-windows.md` for full guide
