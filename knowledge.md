# FitTravel Knowledge Base

> **Last Updated:** Current Session
> **Status:** Active Development — Phase 3 (Local Storage + Trip Management)

---

## 1. App Overview

**Vision:** Create the world's first free, premium fitness travel lifestyle app that eliminates every excuse for staying healthy while traveling.

**Target Cities (Seed Data):** Salt Lake City, Utah

---

## 2. Backend

The project is connected to Supabase (Dreamflow Supabase panel). The app currently uses local storage (SharedPreferences) for data while we complete MVP flows. Migration will target the schema below.

### 2.1 Future Supabase Schema

When transitioning from local storage to Supabase, implement the following database schema:

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
  place_type TEXT CHECK (place_type IN ('gym', 'restaurant', 'park', 'trail', 'other')),
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

#### Community Photos Table (New)
```sql
CREATE TABLE community_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  place_id TEXT NOT NULL, -- Google Places ID or internal saved_places foreign key
  storage_path TEXT NOT NULL, -- points to Supabase Storage object
  captions TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  flagged BOOLEAN DEFAULT false,
  flag_reason TEXT
);

-- Storage bucket recommended: 'community-photos' with public read + write via RLS rules
```

#### Activities Log Table
```sql
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
  activity_type TEXT NOT NULL, -- 'workout', 'meal', 'walk', 'run', etc.
  place_id UUID REFERENCES saved_places(id),
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
  requirement_type TEXT, -- 'streak', 'visits', 'activities', 'cities'
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
- Use Places API for gym/restaurant discovery
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

---

## 5. Feature Categories

### Current Implementation Snapshot (MVP scope)
1. Discover: Gym and Healthy Eating using Google Places API
2. Place Detail: Save/Unsave, Directions/Call/Website, Mark Visited (+XP)
3. Saved Places: Associated to trips, visited state, notes
4. Trip Management:
   - Trips list with Active/Upcoming/Past sections
   - Create/Edit trip (bottom sheets), set Active, delete
   - Trip Detail: status pill, date range, stats, saved places list with add/remove
   - Itinerary editor: day chips, add custom/place items, start time/duration, notes, reorder
   - Trip Activity Timeline: read-only visited log grouped by day within trip dates
5. Place Detail — Community Photos: grid of user photos (local URL add for now)
6. Create Trip — Destination City Autocomplete (Google Places Autocomplete)
5. Error Handling: Global handlers to reduce noisy logs and capture errors

### Gamification Features
1. **XP System** - Earn points for activities
2. **Streaks** - Maintain daily fitness habits
3. **Badges** - Achievement unlocks
4. **Challenges** - Daily/weekly goals

### Future Features
1. **Social** - Connect with other fit travelers
2. **AI Recommendations** - Personalized suggestions
3. **Offline Mode** - Download city guides
4. **Apple Health/Google Fit** - Integration

---

## 6. Local Storage Keys

```dart
// SharedPreferences keys for local storage
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
static const String kReviews = 'reviews';
static const String kHasSeenOnboarding = 'has_seen_onboarding';
static const String kAllBadges = 'all_badges';
static const String kAllChallenges = 'all_challenges';
```

---

## 7. Change Log

| Date | Change | Phase |
|------|--------|-------|
| Session Start | Initial setup, local storage foundation | Phase 1 |
| Current | Discovery screens, save places, place detail actions | Phase 2 |
| Current | Trips list + create/edit + detail + set active | Phase 3 |
| Current | Itinerary editor (day chips, add/reorder, time/duration/notes) | Phase 3 |
| Current | Active Trip card now tappable | Phase 3 |
| Current | Trip header overflow fixed (SliverAppBar layout, ellipsis) | Phase 3 |
| Current | Global error handling added (FlutterError, PlatformDispatcher, runZonedGuarded) | Phase 6 |
| Current | Typography fallbacks added (Inter + Noto) to reduce missing glyph warnings | Phase 6 |
| Current | Trip Activity Timeline added (read-only visited log grouped by day) | Phase 3 |
| Current | Destination Autocomplete in New Trip (Google Places Autocomplete) | Phase 3 |
| Current | Place Detail: Community Photos section (URL add, local storage) | Phase 3 |

---

## 8. Error Handling Strategy

- FlutterError.onError -> present + debugPrint for Dreamflow Debug Console
- PlatformDispatcher.instance.onError -> capture platform/async errors, mark handled
- runZonedGuarded -> capture uncaught zone errors
- Rationale: reduce devtool/inspector noise (e.g., “Id does not exist” after hot restart) and keep actionable logs
