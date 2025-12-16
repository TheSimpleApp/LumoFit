# FitTravel Development Plan

> **Current Phase:** Phase 3 - Trip Management (In Progress)
> **Last Updated:** Current Session

---

## Phase Overview

### Phase 1: Foundation & Core Architecture ✅ COMPLETE
- [x] Project structure setup
- [x] Create knowledge.md and plan.md
- [x] Theme customization (fitness/travel brand colors)
- [x] Data models creation
- [x] Local storage service
- [x] Navigation structure (bottom nav)
- [x] Basic screens scaffold

### Phase 2: Core Discovery Features ✅ COMPLETE
- [x] Home/Dashboard screen
- [x] Gym Finder screen with Google Places API
- [x] Restaurant Finder screen with Google Places API
- [x] Place detail view (full screen)
- [x] Save places functionality

### Phase 3: Trip Management (Current)
- [x] Trip list screen
- [x] Create/Edit trip flow (bottom sheets)
- [x] Trip detail view (status, date range, stats)
- [x] Associate places with trips (from Place Detail + Trip Detail)
- [x] Itinerary editor (day chips, add custom/place items, reorder)
- [x] Trip activity timeline (read‑only visited log grouped by day)
- [x] Destination city autocomplete (Google Places Autocomplete in New Trip)
- [x] Place Detail: Community Photos section (URL add, local storage)

### Phase 4: Activity & Gamification
- [ ] Activity logging
- [ ] XP system implementation
- [ ] Streak tracking
- [ ] Badges system
- [ ] Challenges system
- [ ] Progress visualization

### Phase 5: Profile & Settings
- [ ] User profile screen
- [ ] Settings screen
- [ ] Stats dashboard
- [ ] Achievement showcase

### Phase 6: Polish & Enhancement
- [x] Global error handling baseline (FlutterError, PlatformDispatcher, runZonedGuarded)
- [x] Typography fallbacks to reduce missing glyph warnings (Inter + Noto)
- [ ] Animations & transitions audit (expand beyond current subtle usage)
- [ ] Empty states (review across all screens)
- [ ] Performance optimization
- [ ] Final UI polish

---

## Current Sprint: Phase 3 Tasks

### 1. Trip Surfaces & Navigation
**Status:** ✅ COMPLETE
**Description:** Implement trips list, active trip entry, and navigation to detail

### 2. Create/Edit Trip
**Status:** ✅ COMPLETE
**Description:** Bottom sheets for create and edit with date pickers and notes

### 3. Associate Places & Quick Add
**Status:** ✅ COMPLETE
**Description:** Add from Place Detail ("Add to Trip") and from Trip Detail

### 4. Itinerary Editor (Rich Timeline Editing)
**Status:** ✅ COMPLETE
**Description:** Day chips, add custom/place items, start time/duration, notes, reorder

### 5. Trip Activity Timeline (Read‑Only)
**Status:** ✅ COMPLETE
**Description:** Show visited places grouped by day within trip date range

### 6. Destination Autocomplete (Create Trip)
**Status:** ✅ COMPLETE
**Description:** Google Places Autocomplete for destination city; select fills city/country

### 7. Community Photos on Place Detail
**Status:** ✅ COMPLETE
**Description:** Community Photos grid with Add (URL) bottom sheet; persists via StorageService

---

## Backlog & Upcoming

- Empty states polish for Trips/Itinerary variations
- Performance pass on list builds and animated transitions
- Supabase migration plan (see knowledge.md) and feature parity checklist
- Migrate Community Photos to Supabase Storage + table
- Add photo upload (camera/gallery), moderation/report/report abuse tools
- Add Community Reviews (ratings + text), sorting and filtering; store in Supabase
- Gallery lightbox, pagination/lazy-loading for Community Photos

---

## Technical Decisions

### State Management
- **Provider** for app-wide state
- Local state for UI-specific state

### Data Storage
- **Phase 1:** SharedPreferences for local storage
- **Future:** Supabase (schema documented in knowledge.md)

### APIs
- **Google Places API** for location discovery
- API Key stored in environment config

### Design Approach
- **Vibrant & Energetic** style (per designer instructions)
- Material Design 3 with custom theming
- Consistent Inter font family

---

## Sample Data (Salt Lake City)

### Gyms
1. Vasa Fitness - Downtown SLC
2. Gold's Gym - Sugar House
3. The Gym SLC - Liberty Park
4. Anytime Fitness - 9th & 9th
5. UFC Gym - Sandy

### Healthy Restaurants
1. Cafe Zupa's - Fresh soups & salads
2. Even Stevens - Sandwiches & smoothies
3. Vessel Kitchen - Health-focused menu
4. Roots Cafe - Vegan/Vegetarian
5. Aubergine & Company - Mediterranean

---

## Notes

- All local storage data will have realistic seed data for testing
- Google API key: AIzaSyDReP4tFXyqU6W8PusrlZdFVFLAYwFr6ZA
- Keep architecture clean for easy Supabase migration
