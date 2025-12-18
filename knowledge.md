# FitTravel Knowledge Base

> **Last Updated:** December 2024
> **Status:** Beta Ready — Phase 10 (Beta Testing & QA) In Progress
> **Strategy:** Cloud-synced MVP with Supabase backend, ready for live beta testing

---

## 1. App Overview

**Vision:** Create the world's first free, premium fitness travel lifestyle app that eliminates every excuse for staying healthy while traveling.

**Core Value Props:**
1. Find gyms/food/events → take action (call/directions) → save/add to trip
2. Mark visited → contribute (photos/menu/review) → light gamification
3. Works in the field while traveling (mobile-first, buttery UX)

**Target Cities (Seed Data):** Salt Lake City, Utah

---

## 2. Backend

The project is connected to Supabase (Dreamflow Supabase panel). **All data services now use Supabase** for cloud storage and sync. Phase 9 (Database Migration) was completed in December 2024.

### Current Architecture

- **Database:** Supabase PostgreSQL with Row-Level Security (RLS)
- **Authentication:** Supabase Auth (email/password)
- **Storage:** Supabase Storage for community photos (planned)
- **Edge Functions:** Event aggregation from Eventbrite + RunSignup APIs

### 2.1 Current Supabase Schema

The following database schema is **live and active**:

#### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  home_city TEXT,
  fitness_level TEXT CHECK (fitness_level IN ('beginner', 'intermediate', 'advanced')),
  dietary_preferences TEXT[], -- ['vegetarian', 'vegan', 'gluten-free', etc.]
  current_streak INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  total_xp INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Trips Table
```sql
CREATE TABLE trips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  destination_city TEXT NOT NULL,
  destination_country TEXT,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Saved Places Table
```sql
CREATE TABLE saved_places (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  place_id TEXT NOT NULL, -- Google Places ID
  place_type TEXT CHECK (place_type IN ('gym', 'restaurant', 'park', 'trail', 'event', 'other')),
  name TEXT NOT NULL,
  address TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  rating DECIMAL(2, 1),
  notes TEXT,
  is_visited BOOLEAN DEFAULT false,
  visited_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Community Photos Table
```sql
CREATE TABLE community_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  place_id TEXT NOT NULL, -- Google Places ID or internal saved_places foreign key
  storage_path TEXT NOT NULL, -- points to Supabase Storage object
  photo_type TEXT CHECK (photo_type IN ('general', 'menu', 'interior', 'exterior', 'other')),
  caption TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  flagged BOOLEAN DEFAULT false,
  flag_reason TEXT,
  moderation_status TEXT DEFAULT 'approved' CHECK (moderation_status IN ('pending', 'approved', 'rejected'))
);

-- Storage bucket recommended: 'community-photos' with public read + write via RLS rules
```

#### Reviews Table
```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  place_id TEXT NOT NULL,
  rating INT CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  helpful_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  flagged BOOLEAN DEFAULT false,
  moderation_status TEXT DEFAULT 'approved' CHECK (moderation_status IN ('pending', 'approved', 'rejected'))
);
```

#### Events Table (Phase 4)
```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type TEXT, -- '5k', '10k', 'half-marathon', 'marathon', 'yoga', 'cycling', 'hiking', 'crossfit', 'other'
  name TEXT NOT NULL,
  description TEXT,
  location_name TEXT,
  address TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  website_url TEXT,
  registration_url TEXT,
  external_id TEXT, -- from event API provider
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Trails/Routes Table (Phase 5)
```sql
CREATE TABLE trails (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  difficulty TEXT CHECK (difficulty IN ('easy', 'moderate', 'hard')),
  distance_km DECIMAL(6, 2),
  elevation_gain_m INT,
  location_name TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  safety_notes TEXT,
  lighting_quality TEXT CHECK (lighting_quality IN ('good', 'poor', 'none')),
  route_type TEXT, -- 'running', 'hiking', 'cycling', 'mixed'
  external_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Activities Log Table
```sql
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
  activity_type TEXT NOT NULL, -- 'workout', 'meal', 'walk', 'run', 'event', etc.
  place_id UUID REFERENCES saved_places(id),
  event_id UUID REFERENCES events(id),
  trail_id UUID REFERENCES trails(id),
  title TEXT NOT NULL,
  description TEXT,
  duration_minutes INT,
  calories_burned INT,
  xp_earned INT DEFAULT 0,
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Badges Table
```sql
CREATE TABLE badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  icon_name TEXT,
  xp_reward INT DEFAULT 0,
  requirement_type TEXT, -- 'streak', 'visits', 'activities', 'cities', 'contributions'
  requirement_value INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE user_badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  badge_id UUID REFERENCES badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, badge_id)
);
```

#### Challenges Table
```sql
CREATE TABLE challenges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  challenge_type TEXT, -- 'daily', 'weekly', 'trip'
  xp_reward INT DEFAULT 0,
  requirement_type TEXT,
  requirement_value INT,
  start_date DATE,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE user_challenges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
  progress INT DEFAULT 0,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 3. Google APIs Configuration

### API Key
```
AIzaSyDReP4tFXyqU6W8PusrlZdFVFLAYwFr6ZA
```

### Enabled Services
- Google Places API (New)
- Google Maps SDK

### Usage Notes
- Use Places API for gym/restaurant/park/trail discovery
- Autocomplete: Use Places Autocomplete for destination city in New Trip
- Implement proper caching to minimize API calls
- Store frequently accessed place details locally

---

## 4. Design System

### Typography
- Primary Font: Inter (via Google Fonts)
- Fallbacks: Noto Sans, Noto Color Emoji, Noto Sans Symbols 2 (to reduce missing glyph warnings on web)
- Consistent across iOS/Android/Web

### Color Philosophy
- Dark luxury aesthetic: near‑black surfaces, warm gold primary, minimal borders
- Energetic yet minimal; high contrast for readability during workouts

### UX Principles (Phase 3.5 established)
- **Mobile-first:** Every interaction optimized for thumb reachability
- **Buttery smooth:** 60fps, haptic feedback, subtle transitions
- **Field-ready:** Works while traveling with spotty connection (offline-first future)
- **Clear affordances:** Actions (call, directions, save) always visible and tappable
- **Haptic feedback:** Success actions get double-tap feel, errors vibrate longer (via HapticUtils)

---

## 5. Feature Categories

### Current Implementation Snapshot (MVP scope)

1. **Discover:** Gym and Healthy Eating using Google Places API
   - Search, filters (rating 4.0+, has photos), sorting by community signal
   - Back navigation to return to previous tab
   
2. **Place Detail:** Save/Unsave, Directions/Call/Website, Mark Visited (+XP)
   - Haptic feedback on all key actions
   - Community Photos section (URL add for now)
   
3. **Saved Places:** Associated to trips, visited state, notes

4. **Trip Management:**
   - Trips list with Active/Upcoming/Past sections
   - Active Trip card is tappable
   - Create/Edit trip (bottom sheets), set Active, delete
   - Destination city autocomplete (Google Places Autocomplete)
   - Trip Detail: status pill, date range, stats, saved places list with add/remove
   - Itinerary editor: day chips, add custom/place items, start time/duration, notes, reorder
   - Trip Activity Timeline: read-only visited log grouped by day within trip dates

5. **UX Polish (Phase 3.5 complete):**
   - Haptic feedback via HapticUtils helper
   - Improved empty states with tight copy
   - Standardized IA labels
   - Action consistency across all screens

6. **Error Handling:** Global handlers to reduce noisy logs and capture errors

7. **Quick Add (Camera-first):**
   - Home FAB uses camera icon; captures photo (data URL) and stores as QuickPhoto
   - Profile includes “Quick Added Photos” gallery to manage unassigned shots and assign later to places

### Phase 4 — Events Discovery (In Progress)
- Events surface with filters (date range, categories: running, yoga, hiking, cycling, CrossFit)
- Event detail (location, time/date, website/registration, add-to-itinerary)
- Data source: TBD (Eventbrite, Meetup, sports-specific APIs)

### Phase 5 — Trails/Routes
- Trails/Routes discovery (distance, elevation, safety/lighting)
- Save + add to itinerary
- Data source: Google Places (parks/trails) + trails provider (TBD: AllTrails, TrailLink)

### Phase 6 — Contributions v1 (Photos/Menu/Reviews + AI Moderation)
- Menu contributions (photo-first) + "last updated" label
- Reviews (text + rating + quick prompts)
- AI-gated moderation (nudity/hate/spam rejection, Report action)
- Store locally for now, design for easy DB migration later

### Phase 7 — Gamification Loop
- Trip streak (active trip days), contribution XP, visited XP
- Badges (cities visited, events attended, contributions posted)
- Lightweight progress UI in Home/Profile

### Phase 8 — Feedback Capture
- "Feedback" entrypoint accessible globally
- MVP: text + screenshot attach (optional)
- Optional: AI clarifier chat to help refine feature requests

### Phase 9 — Database/Supabase Migration ✅ COMPLETE

- [x] Supabase project setup with 15 tables and RLS policies
- [x] Authentication integration (email/password signup/login)
- [x] All 8 data services migrated from SharedPreferences to Supabase
- [x] Seeded 14 badges and 5 challenges into database
- [x] Removed StorageService dependency from all services
- [x] Created feedback table for user feedback collection
- [ ] Add admin tooling (web dashboard) after beta demand

### Phase 10 — Beta Testing & QA (CURRENT)

- [ ] Enable leaked password protection in Supabase Dashboard
- [ ] End-to-end testing of auth flow
- [ ] End-to-end testing of trip creation and place saving
- [ ] TestFlight deployment for beta testers
- [ ] Critical path automated tests

---

## 6. Data Storage

**Current:** All user data is stored in Supabase PostgreSQL database with Row-Level Security ensuring data isolation between users.

**Legacy (Deprecated):** The following SharedPreferences keys were used before Phase 9 migration and are no longer active:

```dart
// DEPRECATED - No longer used after Phase 9 Supabase migration
// Kept for reference only
static const String kUserProfile = 'user_profile';
static const String kSavedPlaces = 'saved_places';
static const String kTrips = 'trips';
static const String kActivities = 'activities';
static const String kUserBadges = 'user_badges';
static const String kUserChallenges = 'user_challenges';
static const String kStreak = 'streak_data';
static const String kLastActiveDate = 'last_active_date';
static const String kTripItineraries = 'trip_itineraries';
static const String kCommunityPhotos = 'community_photos';
static const String kQuickPhotos = 'quick_photos';
static const String kReviews = 'reviews';
static const String kHasSeenOnboarding = 'has_seen_onboarding'; // Still used for onboarding state
static const String kAllBadges = 'all_badges';
static const String kAllChallenges = 'all_challenges';
static const String kEvents = 'events'; // Phase 4
static const String kTrails = 'trails'; // Phase 5
```

---

## 7. Product Decisions (from client call)

1. **Events discovery is top priority** after UX polish (5Ks, yoga, hiking groups, cycling, CrossFit drop-ins)
2. **Menu photos** are high-signal: photo-first, "most recent" matters
3. **Contributions need AI moderation**: MVP preference is AI gate (not manual review)
4. **Airport challenges** are low priority for MVP (future idea)
5. **Strava integration** is longer-term consideration
6. **Partnerships/affiliate economics** for events (future monetization path)
7. **Current location** permissions: decide later if required for MVP
8. **Meal photo logging** (Cal AI-like): keep out of MVP scope
9. ~~**No database work until UX flows are validated**~~ → **COMPLETED:** Supabase migration done in Phase 9

---

## 8. Change Log

| Date | Change | Phase |
|------|--------|-------|
| Session Start | Initial setup, local storage foundation | Phase 1 |
| Session | Discovery screens, save places, place detail actions | Phase 2 |
| Session | Trips list + create/edit + detail + set active | Phase 3 |
| Session | Itinerary editor (day chips, add/reorder, time/duration/notes) | Phase 3 |
| Session | Active Trip card now tappable | Phase 3 |
| Session | Trip header overflow fixed (SliverAppBar layout, ellipsis) | Phase 3 |
| Session | Global error handling added (FlutterError, PlatformDispatcher, runZonedGuarded) | Phase 3 |
| Session | Typography fallbacks added (Inter + Noto) to reduce missing glyph warnings | Phase 3 |
| Session | Trip Activity Timeline added (read-only visited log grouped by day) | Phase 3 |
| Session | Destination Autocomplete in New Trip (Google Places Autocomplete) | Phase 3 |
| Session | Place Detail: Community Photos section (URL add, local storage) | Phase 3 |
| Session | Haptic feedback added (HapticUtils helper, all key interactions) | Phase 3.5 |
| Session | Empty states improved with tighter copy | Phase 3.5 |
| Session | IA labels standardized, action consistency ensured | Phase 3.5 |
| Session | Events model + service + Events tab with filters + Event detail | Phase 4 |
| Session | Home Quick Add redesigned (icon-only FAB) + added bottom content spacing | Phase 4 |
| Session | QuickPhoto model/service added (local-first) + Profile “Quick Added Photos” gallery | Phase 4 |
| Session | Home FAB switched to camera-first capture → saved to Quick Photos | Phase 4 |
| Session | Discover TabBar polished (scrollable, no splash, responsive tabs) | Phase 4 |
| Session | Events Edge Function deployed (Eventbrite + RunSignup aggregation) | Phase 4 |
| Session | Supabase Auth integrated (email/password login/signup) | Phase 9 |
| Session | All 8 data services migrated from SharedPreferences to Supabase | Phase 9 |
| Session | Seeded 14 badges and 5 challenges into Supabase database | Phase 9 |
| Session | Removed StorageService, updated main.dart | Phase 9 |
| Session | Created feedback table in Supabase | Phase 9 |
| Current | **Phase 10 IN PROGRESS** — Beta testing & QA | Phase 10 🚧 |

---

## 9. Error Handling Strategy

- FlutterError.onError -> present + debugPrint for Dreamflow Debug Console
- PlatformDispatcher.instance.onError -> capture platform/async errors, mark handled
- runZonedGuarded -> capture uncaught zone errors
- Rationale: reduce devtool/inspector noise (e.g., "Id does not exist" after hot restart) and keep actionable logs

---

## 10. Open Questions & Future Research

### Phase 4 (Events)
- Which event API(s) to use? (Eventbrite, Meetup, sports-specific)
- Pricing constraints for API usage
- Do we need current location permissions for MVP?

### Phase 5 (Trails)
- Which trails API(s) to use? (AllTrails, TrailLink, Google Places)
- Do we need GPS tracking for routes?

### Phase 6 (Contributions)
- Which AI moderation service? (OpenAI Moderation API, AWS Rekognition, etc.)
- Do we need user reputation/trust score to reduce moderation load?

### Phase 9 (Database) ✅ RESOLVED

- [x] Supabase RLS policies design → Implemented with user-based isolation
- [x] Data migration strategy → All services migrated from SharedPreferences to Supabase
- [ ] Admin dashboard requirements → Deferred until post-beta demand

---

## 11. Architecture Notes

### Service Layer (All Supabase-Backed)

- `UserService`: User profile, preferences → `users` table
- `PlaceService`: Saved places, visited state → `saved_places` table
- `TripService`: Trips, active trip, itinerary → `trips`, `trip_places`, `itinerary_items` tables
- `ActivityService`: Activity logging, XP calculation → `activities` table
- `GamificationService`: Streaks, badges, challenges → `badges`, `user_badges`, `challenges`, `user_challenges` tables
- `ReviewService`: Place reviews → `reviews` table
- `CommunityPhotoService`: Community photos → `community_photos` table
- `QuickPhotoService`: Quick capture photos → `quick_photos` table
- `FeedbackService`: User feedback → `feedback` table
- `EventService`: Events discovery (Edge Function API)
- `GooglePlacesService`: Google Places API wrapper (external API)
- `TrailService`: (Phase 5) Trails/routes discovery

### Supabase Integration

- `SupabaseConfig`: Client initialization and auth access
- `SupabaseService`: CRUD helper methods (select, insert, update, delete)
- `SupabaseAuthManager`: Authentication state management

### Utilities

- `HapticUtils`: Centralized haptic feedback patterns (light, medium, heavy, success, error, warning)

### State Management

- **Provider** for app-wide state (services)
- Local state for UI-specific state (search query, tab index, etc.)
- Services use `ChangeNotifier` pattern with `notifyListeners()`

### Navigation

- **go_router** for declarative routing
- Auth guard redirects unauthenticated users to login
- Bottom nav for main tabs (Home, Discover, Trips, Profile)
- Modal routes for detail screens (Place Detail, Trip Detail, Event Detail)

---

## 12. Testing Strategy

### Current Status

Manual testing has been performed for core flows. Automated testing infrastructure is planned for Phase 10.

### Planned Test Infrastructure

**Unit Tests:**

- Model serialization tests (JSON roundtrip for all models)
- Service unit tests (TripService, PlaceService, UserService, GamificationService)
- Business logic tests (XP calculation, streak tracking)

**Widget Tests:**

- LoginScreen form validation
- Critical UI flows (save place, mark visited, create trip)
- Empty state displays

**Integration Tests:**

- Auth flow (signup → login → redirect to home)
- Trip creation flow (create trip → add place → view trip detail)
- Place interaction flow (discover → save → add to trip → mark visited)

**Manual Testing:**

- iOS simulator testing
- Android emulator testing
- Cross-platform consistency verification
- TestFlight beta deployment for real user validation

### Test Dependencies (to add)

```yaml
dev_dependencies:
  mocktail: ^1.0.3
  build_runner: ^2.4.8
  network_image_mock: ^2.1.1
  integration_test:
    sdk: flutter
```
