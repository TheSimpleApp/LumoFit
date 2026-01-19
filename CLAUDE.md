# CLAUDE.md - Claude Code Project Instructions

> **Mode:** Autonomous with `--dangerously-skip-permissions`
> **Sprint:** Door to Door Con (D2D Con) Demo
> **Last Updated:** January 2026

---

## 🤖 You Are Running Autonomously

Claude Code has **full permissions** to:

| Capability | Status | Notes |
|------------|--------|-------|
| Read/Write files | ✅ | All project files |
| Run shell commands | ✅ | flutter, dart, git, etc. |
| Browser automation | ✅ | Test flows, screenshots |
| Build & run app | ✅ | iOS simulator, Android |
| Run tests | ✅ | flutter test |
| Git commits | ✅ | With descriptive messages |
| Use test credentials | ✅ | `test@example.com` / `Test123` |

---

## 📚 Read These First

| Priority | File | Purpose |
|----------|------|---------|
| 1 | `PLAN.md` | Current sprint tasks with checkboxes |
| 2 | `AGENT.md` | Coding patterns and autonomous workflow |
| 3 | `CONTEXT.md` | Business requirements from JC meeting |
| 4 | `TESTING.md` | Test credentials and flows |
| 5 | `knowledge.md` | Full technical documentation |

---

## 🎯 Current Sprint: D2D Con Demo

**Timeline:** ~8 days (Demo around Jan 21, 2026)
**Goal:** Polish & simplify for TestFlight beta

### Sprint Priorities
1. **Map Tab** - Color-coded pins, quick search, distance filters
2. **Discover Tab** - Photo carousel, better cards
3. **Saved Locations** - Quick save without trips, albums
4. **Simplification** - Hide Challenges, Log Activity, complex features
5. **TestFlight** - Public link for conference attendees

---

## 🔄 Autonomous Workflow

### For Each Task:

```
1. READ task from PLAN.md
2. UNDERSTAND requirements
3. IMPLEMENT changes
4. RUN `dart analyze` - fix errors
5. RUN app and TEST feature
6. FIX any issues (feedback loop)
7. UPDATE PLAN.md checkbox [x]
8. COMMIT changes
```

### Feedback Loop (CRITICAL):

```bash
# After every change:
dart analyze lib/
# If errors → fix → repeat
# If clean → continue

# Run app to verify:
flutter run -d "iPhone 15 Pro"
# Test the feature
# If broken → fix → repeat
```

---

## 🧪 Test Credentials

```
Email:    test@example.com
Password: Test123
```

Use these for:
- Login/signup testing
- End-to-end flow testing
- Feature verification
- Browser automation tests

---

## 🏗️ Tech Stack

- **Framework:** Flutter 3.6+ / Dart
- **State:** Provider (NOT Riverpod)
- **Navigation:** GoRouter
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **Maps:** Google Maps Flutter SDK
- **AI:** Gemini 2.5 Flash via Edge Functions

---

## ✅ Code Rules

### DO:
```dart
// Provider for state
class MyService extends ChangeNotifier { ... }

// GoRouter for navigation
context.go('/discover');
context.push('/place/123');

// withValues (not withOpacity)
Colors.white.withValues(alpha: 0.5)
```

### DON'T:
```dart
// ❌ No Navigator.push
Navigator.push(context, MaterialPageRoute(...));

// ❌ No withOpacity (deprecated)
Colors.white.withOpacity(0.5);

// ❌ No setState for shared state
setState(() => _data = newData);
```

---

## 🔧 Common Commands

```bash
# Dependencies
flutter pub get

# Run app
flutter run -d "iPhone 15 Pro"

# Analyze (ALWAYS run after changes)
dart analyze lib/

# Format
dart format lib/

# Test
flutter test

# Build iOS
flutter build ios --no-codesign

# Clean rebuild
flutter clean && flutter pub get
```

---

## 📂 Key Files

| Purpose | File |
|---------|------|
| Entry | `lib/main.dart` |
| Routes | `lib/nav.dart` |
| Theme | `lib/theme.dart` |
| Map screen | `lib/screens/map/map_screen.dart` |
| Discover | `lib/screens/discover/discover_screen.dart` |
| Profile | `lib/screens/profile/profile_screen.dart` |
| Supabase | `lib/supabase/supabase_config.dart` |

---

## 🚫 Sprint Restrictions

During D2D Con sprint:
- ❌ NO new features (polish only)
- ❌ NO architecture changes
- ❌ NO state management changes
- ❌ NO Supabase schema changes
- ❌ NO new dependencies without necessity

---

## ⚠️ AI Model Note

This project uses **Gemini 2.5 Flash** via Supabase Edge Functions.

```
Model ID: gemini-2.5-flash
Location: supabase/functions/
```

Do NOT change AI models without explicit approval.

---

## 📊 Verification Checklist

Before marking any task complete:

```bash
# 1. No analyzer errors
dart analyze lib/
# Expected: "No issues found!"

# 2. Code formatted
dart format lib/

# 3. App runs without crash
flutter run -d "iPhone 15 Pro"

# 4. Feature works as expected
# (manual test or browser automation)

# 5. PLAN.md updated
# Change [ ] to [x] for completed task
```

---

## 🎯 Quick Reference: Sprint Tasks

### Phase D1: Map Tab Polish
- [ ] Color-coded markers (Gyms=Blue, Food=Orange, Trails=Green, Events=Purple)
- [ ] Quick location search bar
- [ ] Distance filters (1mi, 5mi, 10mi, 25mi)

### Phase D2: Discover Tab Polish
- [ ] Photo carousel in place cards
- [ ] Better card shadows/borders
- [ ] Distance badge on cards

### Phase D3: Saved Locations
- [ ] Quick save without trip
- [ ] Albums / Categories

### Phase D4: UI Simplification
- [ ] Hide Challenges from Home
- [ ] Remove Log Activity
- [ ] Simplify Trips or hide

### Phase D5: Events Polish
- [ ] Better date/time formatting
- [ ] Seed Austin/Texas events

### Phase D6: TestFlight Prep
- [ ] Update version to 1.1.0
- [ ] Full flow test
- [ ] Upload to TestFlight
