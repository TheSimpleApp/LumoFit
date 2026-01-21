# FitTravel App Analysis Report

**Generated:** January 20, 2026 23:40 UTC
**Project:** FitTravel (LumoFit)
**Framework:** Flutter 3.6+ / Dart
**Analysis Type:** Code Structure + Live App Running
**App Version:** 1.1.0+2

---

## Executive Summary

FitTravel is a **premium fitness travel app** that helps users maintain their healthy lifestyle while traveling. The app features gym discovery, healthy food options, trail finding, fitness events, and gamified travel challenges. Built with Flutter on a dark luxury design system inspired by Gentler Streak and Slopes.

**Current Status:**
- ✅ App successfully running on Windows desktop
- ✅ VM Service URL active: `ws://127.0.0.1:52132/z7Ey8M6DvVo=/ws`
- ✅ Marionette Flutter integrated (v0.1.0)
- 🚧 In D2D Con Demo sprint (TestFlight prep)

---

## App Architecture

### Navigation Structure

**Bottom Navigation (4 tabs - Trips hidden for demo):**
1. **Home** (`/home`) - Dashboard with quick actions, active challenges, streak
2. **Map** (`/map`) - Google Maps view with location markers
3. **Discover** (`/discover`) - Browse gyms, food, trails, events (5 sub-tabs)
4. **Profile** (`/profile`) - User profile, settings, stats

**Full-Screen Routes:**
- `/place-detail` - Place details with photos, reviews, fitness intelligence
- `/event-detail` - Event details with date, location, registration
- `/trip/:id` - Trip itinerary with activities and recommendations
- `/fitness-guide` - AI Cairo Guide (location-specific fitness advice)
- `/goals` - Set and track fitness goals
- `/challenges` - Browse and join fitness challenges
- `/feedback` - Submit app feedback
- `/generate-itinerary` - AI-powered trip itinerary generator

**Auth Routes:**
- `/login` - Email/password login
- `/signup` - New user registration
- `/forgot-password` - Password reset flow

**Navigation Pattern:**
- GoRouter with shell routing
- Auth state listener (auto-redirect on login/logout)
- No transitions (instant navigation)
- Query parameters for initial state (tabs, filters)

---

## Screen Breakdown

### 27 Total Screens

#### Auth Screens (3)
| File | Purpose | Key Features |
|------|---------|--------------|
| `login_screen.dart` | User login | Email/password, forgot password link |
| `signup_screen.dart` | New user registration | Email, password, profile setup |
| `forgot_password_screen.dart` | Password reset | Email verification |

#### Home Screens (4)
| File | Purpose | Key Features |
|------|---------|--------------|
| `home_screen.dart` | Main dashboard | Quick actions, active challenges, today's activities, streak card |
| `cairo_guide_screen.dart` (FitnessGuideScreen) | AI fitness guide | Location-specific workout tips, chat interface |
| `goals_screen.dart` | Fitness goals | Set weekly goals, track progress |
| `challenges_screen.dart` | Browse challenges | Active/completed tabs, join challenges |

#### Map Screen (1)
| File | Purpose | Key Features |
|------|---------|--------------|
| `map_screen.dart` | Google Maps view | Color-coded markers, filter bar, search bar, place previews |

#### Discover Screens (3)
| File | Purpose | Key Features |
|------|---------|--------------|
| `discover_screen.dart` | Browse places/events | 5 tabs (Gyms, Food, Trails, Events, Saved), filter/sort |
| `place_detail_screen.dart` | Place details | Photos, reviews, fitness intelligence, save/share |
| `event_detail_screen.dart` | Event details | Date/time, location, description, register button |

#### Profile Screens (3)
| File | Purpose | Key Features |
|------|---------|--------------|
| `profile_screen.dart` | User profile | Stats, badges, settings, logout |
| `edit_profile_screen.dart` | Edit profile | Name, bio, photo upload |
| `profile_skeleton.dart` | Loading state | Shimmer skeleton for profile |

#### Trip Screens (3)
| File | Purpose | Key Features |
|------|---------|--------------|
| `trips_screen.dart` | Browse trips | Upcoming/past trips, create new trip |
| `trip_detail_screen.dart` | Trip itinerary | Day-by-day activities, recommendations, AI suggestions |
| `itinerary_generator_screen.dart` | AI trip planner | Destination input, AI-generated itinerary |

#### Utility Screens (1)
| File | Purpose | Key Features |
|------|---------|--------------|
| `feedback_screen.dart` | User feedback | Submit bugs, feature requests |

#### Shell (1)
| File | Purpose |
|------|---------|
| `main_shell.dart` | Bottom nav wrapper |

---

## State Management & Services

### Provider Pattern (11 Services)

All services extend `ChangeNotifier` and are initialized in `main.dart`:

| Service | Responsibility | Key Methods |
|---------|---------------|-------------|
| `UserService` | User auth, profile, preferences | `initialize()`, `updateProfile()`, `logout()` |
| `PlaceService` | Fetch/save places (gyms, food, trails) | `fetchPlaces()`, `savePlace()`, `getPlaceDetails()` |
| `TripService` | Create/manage trips | `createTrip()`, `addActivity()`, `getTrips()` |
| `ActivityService` | Log fitness activities | `logActivity()`, `getActivities()`, `syncStrava()` |
| `GamificationService` | XP, badges, challenges, streaks | `addXP()`, `unlockBadge()`, `updateStreak()` |
| `CommunityPhotoService` | User-generated photos | `uploadPhoto()`, `getPhotos()`, `likePhoto()` |
| `QuickPhotoService` | Quick capture for places | `capturePhoto()`, `attachToPlace()` |
| `ReviewService` | Place reviews/ratings | `submitReview()`, `getReviews()`, `updateReview()` |
| `EventService` | Fetch/register for events | `getEvents()`, `registerForEvent()` |
| `FeedbackService` | Submit user feedback | `submitFeedback()` |
| `StravaService` | Strava API integration | `authenticate()`, `syncActivities()`, `disconnect()` |
| `AiGuideService` (Provider, not ChangeNotifier) | AI chat for fitness advice | `sendMessage()`, `getRecommendations()` |

**Additional Services** (not in Provider tree):
- `GooglePlacesService` - Google Places API wrapper
- `PhotoStorageService` - Supabase Storage for images
- `StorageService` - Generic file storage

---

## Backend Integration

### Supabase

**Configuration:** `lib/supabase/supabase_config.dart`

**Features Used:**
- **Auth:** Email/password authentication, session management
- **Database:** PostgreSQL for all app data
- **Storage:** Photo uploads (community photos, profile pictures, place images)
- **Edge Functions:** AI features (Gemini 2.5 Flash integration)

**Database Schema (implied from models):**
- `users` - User profiles, XP, badges, streaks
- `places` - Gyms, restaurants, trails (cached from Google Places)
- `events` - Fitness events, workshops
- `trips` - User trip itineraries
- `activities` - Logged workouts/activities
- `reviews` - Place reviews and ratings
- `challenges` - Fitness challenges
- `saved_places` - User-saved locations
- `community_photos` - User-uploaded photos

---

## Models (Data Layer)

### 15 Model Files

| Model | Purpose |
|-------|---------|
| `user_model.dart` | User profile, stats, preferences |
| `place_model.dart` | Gym, restaurant, trail data |
| `event_model.dart` | Fitness event details |
| `trip_model.dart` | Trip itinerary, dates, destination |
| `itinerary_item.dart` | Single activity in trip |
| `activity_model.dart` | Logged workout/activity |
| `challenge_model.dart` | Fitness challenge details |
| `badge_model.dart` | Achievement badges |
| `review_model.dart` | Place review with rating |
| `community_photo.dart` | User-uploaded photos |
| `quick_photo.dart` | Quick-capture photos for places |
| `ai_models.dart` | AI chat messages, responses |
| `models.dart` | Barrel file (exports all models) |

---

## Widgets & Components

### 10 Reusable Widget Files

| Widget File | Components |
|-------------|------------|
| `widgets.dart` | Barrel file (exports all widgets) |
| `ai_map_concierge.dart` | Floating AI assistant for map |
| `details_action_bar.dart` | Save/share/navigate buttons for places |
| `empty_state_widget.dart` | Empty list placeholder |
| `empty_state_illustrations.dart` | Custom empty state graphics |
| `place_fitness_intelligence_card.dart` | AI-generated place insights |
| `place_insights_card.dart` | Place statistics and info |
| `place_quick_insights.dart` | Quick facts about place |
| `polish_widgets.dart` | Polished UI components (badges, cards) |
| `skeleton_loader.dart` | Loading state shimmer |

**Home Screen Widgets** (`lib/screens/home/widgets/`):
- `widgets.dart` - Barrel file
- `active_challenges.dart` - Active challenges carousel
- `quick_actions.dart` - Quick action buttons (log activity, find gym, etc.)
- `streak_card.dart` - Streak visualization
- `today_activities.dart` - Today's logged activities

**Map Screen Widgets** (`lib/screens/map/widgets/`):
- `location_search_bar.dart` - Search for locations
- `map_filter_bar.dart` - Filter by category (gyms, food, trails)
- `map_place_preview.dart` - Bottom sheet place preview

---

## Design System

### Theme: Dark Luxury

**Inspiration:** Gentler Streak, Slopes, Opal

**Color Palette:**
- **Background:** Pure black (`#0A0A0A`)
- **Surface:** Dark gray (`#1A1A1A`, `#242424`)
- **Primary:** Warm gold (`#E8C547`) - used sparingly
- **Text:** White/Gray hierarchy

**Typography:**
- **Font:** Inter (Google Fonts)
- **Scales:** Display (48px) → Label (11px)
- **Weights:** 700 (bold), 600 (semibold), 500 (medium), 400 (regular)

**Spacing System:**
- XS: 4px, SM: 8px, MD: 16px, LG: 24px, XL: 32px, XXL: 48px, XXXL: 64px

**Border Radius:**
- XS: 8px, SM: 12px, MD: 16px, LG: 20px, XL: 24px, XXL: 32px, Full: 999px

**Component Patterns:**
- Cards: Surface color, 1px border, no shadow
- Buttons: Gold primary, minimal outline secondary
- Inputs: Surface fill, border, no shadow
- Bottom nav: 4 tabs, gold accent for selected

---

## Key Dependencies

### Core Flutter Packages
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Framework |
| `provider` | ^6.1.2 | State management |
| `go_router` | ^16.1.0 | Navigation |
| `supabase_flutter` | >=1.10.0 | Backend |
| `google_maps_flutter` | ^2.5.3 | Maps |
| `marionette_flutter` | ^0.1.0 | Testing/automation |

### UI/UX Packages
| Package | Purpose |
|---------|---------|
| `google_fonts` ^6.1.0 | Inter font family |
| `flutter_animate` ^4.0.0 | Animations |
| `shimmer` ^3.0.0 | Loading skeletons |
| `cached_network_image` ^3.0.0 | Image caching |
| `image_picker` ^1.0.7 | Photo capture/upload |
| `vibration` ^3.0.0 | Haptic feedback |

### Utility Packages
| Package | Purpose |
|---------|---------|
| `geolocator` 13.0.4 | Location services |
| `url_launcher` any | Open external URLs |
| `http` ^1.0.0 | HTTP requests |
| `intl` 0.20.2 | Internationalization |
| `uuid` ^4.0.0 | Unique IDs |
| `shared_preferences` ^2.0.0 | Local storage |
| `flutter_secure_storage` ^9.2.2 | Secure token storage (Strava) |

### Map Packages
| Package | Purpose |
|---------|---------|
| `google_maps_flutter_web` any | Web support |
| `flutter_polyline_points` ^2.0.0 | Route polylines |
| `flutter_markdown` ^0.7.4 | Markdown rendering |

---

## Current Sprint: D2D Con Demo

### Sprint Configuration

**Timeline:** ~8 days until Jan 21, 2026 demo
**Goal:** Polish & simplify for TestFlight beta at Door to Door Con conference

**UI Simplifications:**
- ✅ Trips tab hidden from bottom nav (4-tab layout)
- ✅ Challenges hidden from home screen (still accessible via `/challenges`)
- 🚧 Map tab enhancements (color-coded pins, search, filters)
- 🚧 Discover tab polish (photo carousel, better cards)
- 🚧 Saved locations quick-save

**See `PLAN.md` for detailed task list**

---

## Code Quality & Patterns

### ✅ Strengths

1. **Consistent Architecture**
   - Clean separation: models, services, screens, widgets
   - Provider pattern used throughout
   - GoRouter with shell routing

2. **Design System**
   - Comprehensive theme in `theme.dart`
   - Consistent spacing, typography, colors
   - Reusable component patterns

3. **Modern Flutter Practices**
   - Material 3 design
   - `withValues(alpha:)` instead of deprecated `withOpacity()`
   - Proper error handling in `main.dart`

4. **Backend Integration**
   - Centralized Supabase config
   - Auth state management
   - Edge Functions for AI features

5. **Testing Ready**
   - Marionette integration
   - Test credentials: `test@example.com` / `Test123`
   - Proper dev/prod environment handling

### ⚠️ Areas to Watch

1. **API Key Management**
   - Google Places API key uses development fallback
   - Should use environment variables for production

2. **Commented Code**
   - Some features commented out for demo (Trips tab, Cairo Guide redirect)
   - Clean up before production release

3. **Missing Tests**
   - Unit tests for services
   - Widget tests for complex screens
   - Integration tests for critical flows

---

## Interactive Elements (Code Analysis)

### Home Screen
- **Quick Actions**: 4 buttons (Log Activity, Find Gym, Discover Events, Plan Trip)
- **Active Challenges**: Horizontal scroll carousel
- **Streak Card**: Tap to view streak details
- **Today's Activities**: List of logged activities

### Map Screen
- **Map View**: Pan, zoom, tap markers
- **Search Bar**: Text input for location search
- **Filter Bar**: Category chips (Gyms, Food, Trails, Events)
- **Place Preview**: Bottom sheet with place details

### Discover Screen
- **Tab Bar**: 5 tabs (Gyms, Food, Trails, Events, Saved)
- **Filter/Sort**: Dropdown menus
- **Place Cards**: Tap to view details, swipe to save
- **Pull-to-Refresh**: Refresh place list

### Profile Screen
- **Edit Profile**: Button to edit screen
- **Stats Grid**: XP, badges, level display
- **Settings**: Toggle switches
- **Logout**: Confirmation dialog

### Place Detail Screen
- **Photo Carousel**: Swipe through photos
- **Action Bar**: Save, share, navigate buttons
- **Reviews**: Star rating, review list
- **AI Insights**: Fitness intelligence card

---

## Recommended Next Steps

### 1. Complete Live Analysis
To get screenshots and interactive element details:

**Option A: Restart Claude Code with Marionette MCP**
```bash
# Close Claude Code
# Add marionette to claude_desktop_config.json
# Restart Claude Code
# Re-run `/analyze-app`
```

**Option B: Use Claude Desktop**
- Add Marionette config to `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "marionette": {
      "command": "npx",
      "args": ["-y", "@leancode/marionette-mcp"]
    }
  }
}
```
- Open Claude Desktop
- Run `/analyze-app` from there

### 2. Extract Standards
Run `/discover-standards` to document:
- Flutter component patterns
- Screen layouts
- Navigation conventions
- Service/state management patterns

### 3. Plan Sprint Tasks
Use `/plan-feature` with this analysis for:
- Map tab color-coded pins
- Discover tab photo carousel
- Saved locations quick-save

### 4. TestFlight Prep
Before demo:
- [ ] Complete D2D Con sprint tasks (see `PLAN.md`)
- [ ] Full end-to-end test flow
- [ ] Update version to 1.1.0 (build 2+)
- [ ] Generate TestFlight public link

---

## Technical Stack Summary

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.6+ / Dart |
| **State** | Provider (ChangeNotifier pattern) |
| **Navigation** | GoRouter with shell routes |
| **Backend** | Supabase (PostgreSQL, Auth, Storage, Edge Functions) |
| **Maps** | Google Maps Flutter SDK |
| **AI** | Gemini 2.5 Flash (via Supabase Edge Functions) |
| **Design** | Material 3, Inter font, dark luxury theme |
| **Testing** | Marionette Flutter, flutter_test, integration_test |

---

## Files Analyzed

**Total Dart Files:** 80+

**Key Files:**
- `lib/main.dart` - App entry, providers, error handling
- `lib/nav.dart` - GoRouter configuration
- `lib/theme.dart` - Complete design system
- `lib/screens/` - 27 screen files
- `lib/services/` - 17 service files
- `lib/models/` - 15 model files
- `lib/widgets/` - 10 reusable widget files
- `lib/supabase/supabase_config.dart` - Backend config

---

## Marionette Configuration

**Status:** ✅ Installed (`marionette_flutter: ^0.1.0`)

**Binding:** Initialized in `main.dart`:
```dart
MarionetteBinding.ensureInitialized(const MarionetteConfiguration());
```

**VM Service URL (live session):**
```
ws://127.0.0.1:52132/z7Ey8M6DvVo=/ws
```

**MCP Config Created:**
- Location: `C:\Users\dotso\.config\claude-code\mcp.json`
- Server: `@leancode/marionette-mcp`
- Next step: Restart Claude Code or use Claude Desktop

---

## App State (Live)

**Running On:** Windows Desktop
**Build:** Debug mode
**Supabase:** Connected to `lwyuwxqwshflmuefxgay.supabase.co`
**Warnings:** Google Places API using development fallback (expected in dev mode)

---

*Analysis completed by Claude Code*
*For questions or updates, refer to `CLAUDE.md`, `PLAN.md`, `AGENT.md`*
