# AGENT.md - Claude Code Autonomous Development Guide

> **Purpose:** Instructions for Claude Code operating in autonomous mode with `--dangerously-skip-permissions`
> **Last Updated:** January 2026
> **Sprint:** Door to Door Con (D2D Con) Demo
> **Mode:** Full autonomous - browser automation, build, test, deploy

---

## 🤖 Autonomous Capabilities

Claude Code is running with **full permissions** and can:

### Build & Run
- ✅ Run `flutter run` to launch app on simulator/device
- ✅ Run `flutter build ios` / `flutter build apk`
- ✅ Run `dart analyze` and fix issues
- ✅ Run `dart format lib/`
- ✅ Install dependencies with `flutter pub get`
- ✅ Run tests with `flutter test`

### Browser Automation
- ✅ Open URLs and interact with web pages
- ✅ Navigate Supabase dashboard
- ✅ Check TestFlight status
- ✅ Verify deployed Edge Functions
- ✅ Take screenshots for visual testing

### Testing with Credentials
- ✅ **Test Email:** `test@example.com`
- ✅ **Test Password:** `Test123`
- ✅ Create test accounts, login, test flows
- ✅ Run end-to-end tests with real data

### Self-Correction Loop
- ✅ Run code → Check output → Fix errors → Repeat
- ✅ Read error logs and stack traces
- ✅ Modify code to fix issues
- ✅ Verify fixes by re-running

---

## 🎯 Current Sprint Context

**Event:** Door to Door Con (~8 days)
**Goal:** Public TestFlight beta with polished Map + Discover experience
**Focus:** Visual polish, simplification, NOT new features

### Sprint Priorities (from JC meeting)
1. **Map Tab** - Color-coded pins, quick location search
2. **Discover Tab** - Photo carousel, visual improvements
3. **Remove clutter** - Hide Challenges, Log Activity, complex Trips
4. **Keep Events** - Users will test this for feedback
5. **Saved Locations** - Quick save without trip, albums/categories

---

## 🔄 Autonomous Workflow

### For Each Task:

```
1. READ task from PLAN.md
2. UNDERSTAND requirements from CONTEXT.md
3. LOCATE relevant files
4. IMPLEMENT changes
5. RUN `dart analyze` - fix any errors
6. RUN `flutter run -d iPhone` or simulator
7. TEST the feature manually or via browser automation
8. VERIFY visually (take screenshot if needed)
9. FIX any issues found
10. UPDATE PLAN.md checkbox when complete
11. COMMIT changes with descriptive message
```

### Feedback Loop Pattern:

```bash
# 1. Make changes
# 2. Analyze
dart analyze lib/

# 3. If errors, fix them and repeat
# 4. Format
dart format lib/

# 5. Run app
flutter run -d "iPhone 15 Pro"

# 6. Test feature
# 7. If issues, fix and repeat from step 1
```

---

## 🏗️ Project Architecture

### Tech Stack
- **Framework:** Flutter 3.6+ / Dart
- **State Management:** Provider (NOT Riverpod)
- **Navigation:** GoRouter 16.x
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **Maps:** Google Maps Flutter SDK
- **AI:** Gemini 2.5 Flash via Supabase Edge Functions

### Folder Structure
```
lib/
├── auth/              # Authentication managers
├── config/            # App configuration (API keys)
├── models/            # Data models
├── screens/           # Screen widgets organized by feature
│   ├── auth/          # Login, signup, forgot password
│   ├── discover/      # Discover tab, place detail, event detail
│   ├── feedback/      # In-app feedback
│   ├── home/          # Home tab, challenges, goals
│   ├── map/           # Map tab with filters
│   ├── profile/       # User profile
│   └── trips/         # Trip management, itinerary
├── services/          # Business logic and API services
├── supabase/          # Supabase configuration
├── utils/             # Utilities (haptics, etc.)
└── widgets/           # Shared widgets
```

---

## 📝 Coding Conventions

### File Naming
- Files: `snake_case.dart` (e.g., `place_detail_screen.dart`)
- Classes: `PascalCase` (e.g., `PlaceDetailScreen`)
- Variables: `camelCase` (e.g., `selectedPlace`)
- Constants: `camelCase` (e.g., `primaryColor`)

### Import Order
```dart
// 1. Dart imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports (alphabetical)
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// 4. Project imports (relative)
import '../models/place_model.dart';
import '../services/place_service.dart';
```

### State Management Pattern
```dart
// Services extend ChangeNotifier
class PlaceService extends ChangeNotifier {
  List<Place> _places = [];
  bool _isLoading = false;

  List<Place> get places => _places;
  bool get isLoading => _isLoading;

  Future<void> loadPlaces() async {
    _isLoading = true;
    notifyListeners();

    try {
      _places = await _fetchFromSupabase();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Access in widgets via Provider
Consumer<PlaceService>(
  builder: (context, service, child) {
    if (service.isLoading) return CircularProgressIndicator();
    return ListView.builder(...);
  },
)
```

### Navigation Pattern
```dart
// Use GoRouter for navigation
context.go('/discover');           // Replace current route
context.push('/place/${place.id}'); // Push onto stack

// Route definitions in nav.dart
GoRoute(
  path: '/place/:id',
  builder: (context, state) => PlaceDetailScreen(
    placeId: state.pathParameters['id']!,
  ),
),
```

---

## 🎨 Theme & Styling

### Current Theme: Dark Luxury
- **Primary:** Gold accent (#FFD700 variants)
- **Background:** Dark grays (#121212, #1E1E1E)
- **Surface:** Slightly lighter (#2C2C2C)
- **Text:** White/gray hierarchy

### Widget Patterns
```dart
// Use theme colors, not hardcoded
Theme.of(context).colorScheme.primary
Theme.of(context).textTheme.headlineMedium

// Card pattern
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.1),
    ),
  ),
)

// IMPORTANT: Use withValues instead of deprecated withOpacity
Colors.white.withValues(alpha: 0.5)  // ✅ Correct
Colors.white.withOpacity(0.5)        // ❌ Deprecated
```

---

## 🗄️ Supabase Patterns

### Query Pattern
```dart
// Fetch with select
final response = await SupabaseConfig.client
    .from('saved_places')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: false);

// Insert
await SupabaseConfig.client
    .from('saved_places')
    .insert({'name': name, 'user_id': userId});

// Update
await SupabaseConfig.client
    .from('saved_places')
    .update({'is_visited': true})
    .eq('id', placeId);
```

### Edge Function Call
```dart
final response = await SupabaseConfig.client.functions.invoke(
  'egypt_fitness_guide',
  body: {'query': userMessage, 'destination': 'Cairo'},
);

if (response.status == 200) {
  final data = response.data as Map<String, dynamic>;
  // Process response
}
```

---

## 🧪 Testing Guide

### Test Credentials
- **Email:** `test@example.com`
- **Password:** `Test123`

### Manual Test Flow
```bash
# 1. Launch app
flutter run -d "iPhone 15 Pro"

# 2. Test auth flow
# - Open app
# - Tap "Sign Up" or "Login"
# - Enter test credentials
# - Verify successful login

# 3. Test Map tab
# - Navigate to Map
# - Verify markers load
# - Test filter buttons
# - Test search (if implemented)

# 4. Test Discover tab
# - Navigate to Discover
# - Verify places load
# - Test category filters
# - Open place detail

# 5. Test save flow
# - Save a place
# - Verify in Profile > Saved
```

### Automated Checks
```bash
# Static analysis
dart analyze lib/

# Format check
dart format --set-exit-if-changed lib/

# Run tests
flutter test

# Build check
flutter build ios --no-codesign
```

---

## 🚫 What NOT to Do

### During D2D Con Sprint
- ❌ Add new features (focus on polish)
- ❌ Refactor architecture
- ❌ Change state management approach
- ❌ Add new dependencies without necessity
- ❌ Modify Supabase schema

### General
- ❌ Use `setState` for app-wide state (use Provider)
- ❌ Use `Navigator.push` directly (use GoRouter)
- ❌ Use `print()` for logging (use proper logging)
- ❌ Hardcode API keys (use environment config)
- ❌ Use `withOpacity()` (use `withValues()`)
- ❌ Leave commented-out code
- ❌ Skip the feedback loop (always verify changes)

---

## ✅ Pre-Commit Checklist

Before committing changes:

```bash
# 1. No analyzer errors
dart analyze lib/
# Must show: No issues found!

# 2. Format code
dart format lib/

# 3. Test on iOS
flutter run -d "iPhone 15 Pro"

# 4. Verify feature works
# (manual testing or browser automation)

# 5. Update PLAN.md checkbox
# Mark completed task as [x]

# 6. Commit with descriptive message
git add .
git commit -m "feat(map): add color-coded markers by place type"
```

---

## 📱 Key Files Reference

| Purpose | File |
|---------|------|
| App entry | `lib/main.dart` |
| Navigation/routes | `lib/nav.dart` |
| Theme | `lib/theme.dart` |
| Supabase config | `lib/supabase/supabase_config.dart` |
| API config | `lib/config/app_config.dart` |
| All models | `lib/models/models.dart` |
| All services | `lib/services/services.dart` |

---

## 🎯 Sprint-Specific Instructions

### For Map Tab Work
- Map screen: `lib/screens/map/map_screen.dart`
- Filter bar: `lib/screens/map/widgets/map_filter_bar.dart`
- Place preview: `lib/screens/map/widgets/map_place_preview.dart`
- Add color-coded markers by place type (gym=blue, food=orange, trails=green)

### For Discover Tab Work
- Main screen: `lib/screens/discover/discover_screen.dart`
- Place detail: `lib/screens/discover/place_detail_screen.dart`
- Event detail: `lib/screens/discover/event_detail_screen.dart`
- Add photo carousel in place cards

### For Navigation Simplification
- Main shell: `lib/screens/main_shell.dart`
- Routes: `lib/nav.dart`
- Hide Home tab items: Challenges, Log Activity
- Keep 5 tabs: Home, Map, Discover, Trips, Profile

### For Saved Locations
- Profile screen: `lib/screens/profile/profile_screen.dart`
- Place service: `lib/services/place_service.dart`
- Add albums/categories for saved places
- Quick save without requiring trip

---

## 🔧 Common Commands

```bash
# Get dependencies
flutter pub get

# Run on iOS simulator
flutter run -d "iPhone 15 Pro"

# Run on specific device
flutter devices  # List available devices
flutter run -d <device_id>

# Hot reload (while running)
# Press 'r' in terminal

# Hot restart
# Press 'R' in terminal

# Analyze code
dart analyze lib/

# Format code
dart format lib/

# Run tests
flutter test

# Build iOS (no codesign for testing)
flutter build ios --no-codesign

# Build release iOS
flutter build ipa

# Clean build
flutter clean && flutter pub get
```

---

## 📞 Communication

- **Slack:** Primary communication channel
- **Fireflies:** Meeting transcripts for context
- **GitHub:** Code and issues

When in doubt, check:
1. `PLAN.md` for current tasks
2. `CONTEXT.md` for business requirements
3. `TESTING.md` for test flows and credentials
4. `knowledge.md` for technical details
