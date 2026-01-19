# Claude Code Rules for LumoFit

## Mode: Autonomous with Full Permissions

You are running with `--dangerously-skip-permissions`. You can:
- Read/write any file
- Run any shell command
- Use browser automation
- Build and run the app
- Run tests
- Make git commits

## Test Credentials
- Email: `test@example.com`
- Password: `Test123`

---

## Current Sprint: D2D Con Demo (~8 days)

### Priorities
1. Map Tab - Color-coded pins, search, filters
2. Discover Tab - Photo carousel, better cards
3. Saved Locations - Quick save, albums
4. UI Simplification - Hide clutter
5. TestFlight - Public link

### Restrictions
- ❌ NO new features (polish only)
- ❌ NO architecture changes
- ❌ NO new dependencies without necessity
- ❌ NO Supabase schema changes

---

## Autonomous Workflow

For every task:

```
1. Read task from PLAN.md
2. Implement changes
3. Run: dart analyze lib/
4. Fix errors, repeat step 3
5. Run: flutter run -d "iPhone 15 Pro"
6. Test feature
7. Fix issues, repeat from step 2
8. Mark PLAN.md checkbox [x]
9. Commit with descriptive message
```

---

## Code Rules

### State Management
```dart
// ✅ Use Provider
class MyService extends ChangeNotifier { ... }
Consumer<MyService>(builder: ...)

// ❌ Don't use
Riverpod, BLoC, GetX, setState for shared state
```

### Navigation
```dart
// ✅ Use GoRouter
context.go('/discover');
context.push('/place/123');

// ❌ Don't use
Navigator.push(context, MaterialPageRoute(...));
```

### Colors
```dart
// ✅ Use withValues
Colors.white.withValues(alpha: 0.5)

// ❌ Deprecated
Colors.white.withOpacity(0.5)
```

---

## Key Files

| Purpose | File |
|---------|------|
| Entry | `lib/main.dart` |
| Routes | `lib/nav.dart` |
| Theme | `lib/theme.dart` |
| Map | `lib/screens/map/map_screen.dart` |
| Discover | `lib/screens/discover/discover_screen.dart` |
| Profile | `lib/screens/profile/profile_screen.dart` |

---

## Commands

```bash
# Dependencies
flutter pub get

# Run
flutter run -d "iPhone 15 Pro"

# Analyze (ALWAYS after changes)
dart analyze lib/

# Format
dart format lib/

# Test
flutter test

# Build
flutter build ios --no-codesign

# Clean
flutter clean && flutter pub get
```

---

## Verification Checklist

Before marking task complete:
- [ ] `dart analyze lib/` shows "No issues found!"
- [ ] App runs without crash
- [ ] Feature works correctly
- [ ] PLAN.md checkbox updated [x]
