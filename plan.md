# LumoFit Development Plan

> **Current Sprint:** Door to Door Con (D2D Con) Demo
> **Sprint Start:** January 13, 2026
> **Demo Date:** ~January 21, 2026 (8 days)
> **Last Updated:** January 19, 2026
> **Strategy:** Polish & simplify existing features for public TestFlight beta
> **Mode:** Claude Code Autonomous (`--dangerously-skip-permissions`)

---

## 🤖 Claude Code Autonomous Workflow

### Test Credentials
```
Email:    test@example.com
Password: Test123
```

### For Each Task
```
1. READ this task from the backlog below
2. LOCATE relevant files (see AGENT.md for file map)
3. IMPLEMENT the changes
4. RUN: dart analyze lib/
5. FIX any errors and repeat step 4
6. RUN: flutter run -d "iPhone 15 Pro"
7. TEST the feature manually
8. FIX any issues and repeat from step 3
9. UPDATE: Mark checkbox [x] in this file
10. COMMIT: git add . && git commit -m "feat(area): description"
```

### Verification Before Marking Complete
```bash
dart analyze lib/              # Must show "No issues found!"
dart format lib/               # Format code
flutter run -d "iPhone 15 Pro" # App must launch without crash
# Feature must work as expected
```

---

## 🎯 D2D Con Sprint Goal

Ship a **polished, simplified LumoFit experience** for D2D Con attendees to demo. Focus on:
- **Map + Discover** as the core experience
- **Visual polish** (photos, colors, animations)
- **Simplification** (hide clutter, streamline flows)
- **Public TestFlight** for select conference attendees

---

## 📋 D2D Con Sprint Backlog

### Phase D1: Map Tab Polish ⬜ IN PROGRESS

**Goal:** Make the Map tab the hero feature with color-coded pins and quick search

- [x] Color-coded map markers (Gyms=Blue, Food=Orange, Trails=Green, Events=Purple)
- [x] Quick location search bar at top of map
- [x] Distance filters (1mi, 5mi, 10mi, 25mi)
- [x] Smooth marker clustering for dense areas
- [x] Better place preview card animations

### Phase D2: Discover Tab Polish ✅ COMPLETE

- [x] Photo carousel in place cards (3-5 photos horizontal scroll)
- [x] Better card shadows and borders
- [x] Rating stars visualization
- [x] Distance badge on cards
- [x] Open/closed status indicator

### Phase D3: Saved Locations / Albums ✅ COMPLETE

- [x] Quick save without trip (general collection)
- [x] Albums / Categories (using place types: Gyms, Food, Trails)
- [x] Saved places grid view with photo-first cards
- [x] Filter saved places by album

### Phase D4: UI Simplification ⬜ PENDING

- [ ] Hide Challenges section from Home
- [ ] Remove Log Activity button
- [ ] Simplify Trips tab or hide it
- [ ] Hide Cairo Guide (Egypt-specific)
- [ ] Consider 4-tab layout: Home, Map, Discover, Profile

### Phase D5: Events Polish ⬜ PENDING

- [ ] Better date/time formatting
- [ ] Event image prominently displayed
- [ ] Seed Austin/Texas events for D2D Con

### Phase D6: TestFlight Prep ⬜ PENDING

- [ ] Update version to 1.1.0
- [ ] Full flow test on iOS device
- [ ] Upload to TestFlight
- [ ] Enable public link

---

## 📝 Notes from JC Meeting (Jan 13, 2026)

Key decisions:
1. **Map + Discover are the focus** - Everything else is secondary
2. **Remove clutter** - Challenges, Log Activity, complex trip features
3. **Keep Events** - Want user feedback on this feature
4. **Visual polish matters** - Photos, colors, smooth animations
5. **Quick save** - Don't force trip creation to save a place
6. **Albums for organization** - Let users categorize saved places
7. **TestFlight public link** - For D2D Con attendees
8. **Slack for comms** - Quick feedback loop during sprint

---

## ✅ Completed Phases (Prior to D2D Sprint)

### Goals (from original client call)

- Ship a **buttery, mobile-first MVP** that works in the field while traveling: find gyms/food/events → take action (call/directions) → save/add to trip → mark visited → contribute (photos/menu/review) → light gamification.
- **Hold off on database/Supabase** until UX is proven. Keep all product decisions logged in `knowledge.md` and execution plan in `plan.md`.
- Prioritize **Events discovery** next (5Ks/yoga/etc), then expand into trails/routes and deeper gamification.

---

## Current Baseline (Already Implemented)

- ✅ Discover (Gyms + Food) using Google Places
- ✅ Place detail (actions + save)
- ✅ Trips (create/edit, destination autocomplete, associate places)
- ✅ Itinerary editor + read-only trip activity timeline
- ✅ Community Photos (URL-based, local storage)
- ✅ UX polish (haptics, empty states, copy refinement, action consistency)
- ✅ Home FAB = camera-first Quick Add (captures photo as data URL)
- ✅ Profile: “Quick Added Photos” gallery (unassigned shots, assign later to places)

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

### Phase 3: Trip Management ✅ COMPLETE
- [x] Trip list screen
- [x] Create/Edit trip flow (bottom sheets)
- [x] Trip detail view (status, date range, stats)
- [x] Associate places with trips (from Place Detail + Trip Detail)
- [x] Itinerary editor (day chips, add custom/place items, reorder)
- [x] Trip activity timeline (read‑only visited log grouped by day)
- [x] Destination city autocomplete (Google Places Autocomplete in New Trip)
- [x] Place Detail: Community Photos section (URL add, local storage)

### Phase 3.5: UX/Polish Pass ✅ COMPLETE
**Intent:** Lock the core flows with production-grade UX before adding net-new surfaces
- [x] Haptic feedback on all key interactions (save, mark visited, create trip, navigate)
- [x] Improved empty states with tighter copy (Discover, Trips, Saved)
- [x] Standardized IA labels and copy ("Visited", "Add to Trip", "Save", "Directions")
- [x] Action consistency (call/directions/website always accessible)
- [x] Created HapticUtils helper for consistent feedback patterns

**Files touched:**
- `lib/utils/haptic_utils.dart` (new)
- `lib/screens/discover/discover_screen.dart`
- `lib/screens/discover/place_detail_screen.dart`
- `lib/screens/trips/trips_screen.dart`
- `lib/screens/trips/trip_detail_screen.dart`

### Phase 4: Events Discovery ✅ COMPLETE
**Intent:** Let users find **active lifestyle events** near a destination or current location and add them into trips.

- [x] Add `event_model.dart` and `event_service.dart`
- [x] Add **Events** surface to Discover (new tab)
- [x] Filters: date range, categories (running, yoga, hiking, cycling, CrossFit)
- [x] Event detail: location, time/date, website/registration, add-to-itinerary
- [x] Home FAB → camera-first Quick Add flow (saves to Quick Photos)
- [x] Profile → Quick Added Photos section (unassigned shots)
- [x] Decide and implement MVP data sources:
  - Providers: Eventbrite + RunSignup via Supabase Edge Functions (combined aggregator)
  - Normalized schema: id, title, category, start/end, venue, address, lat/lon, url, registrationUrl, imageUrl, source
  - Location-aware lookup using current device location with SLC fallback
  - Later: optional Strava API tie-in

**Files likely involved:**
- `lib/models/event_model.dart` (new)
- `lib/services/event_service.dart` (new)
- `lib/screens/discover/discover_screen.dart`
- `lib/screens/discover/event_detail_screen.dart` (new)

### Phase 5: Trails/Routes Discovery ✅ COMPLETE
**Intent:** Help travelers find good/safe runs/hikes without needing Strava-level infrastructure.

- [x] Add "Trails/Routes" discovery with:
  - Basic trail cards (distance, elevation if available, safety/lighting notes if available)
  - Save + add to itinerary
- [x] Choose MVP source(s): Google Places (hiking_area)

**Files likely involved:**
- `lib/screens/discover/discover_screen.dart`
- `lib/screens/discover/place_detail_screen.dart` (reuse for trail details)

### Phase 6: Contributions v1 (Photos/Menu/Reviews + AI Moderation) ✅ COMPLETE
**Intent:** Unlock the community flywheel without a heavy admin workflow.

- [x] Place detail: Community Photos (photo-first) with AI moderation
- [x] Add **Reviews** (short text + rating) with AI moderation
- [x] AI-gated moderation (MVP spec):
  - Client-side pre-check UI states ("Checking…" → publish/reject)
  - Reject nudity/hate/spam; allow user **Report** action
- [x] Store locally for now; design interfaces so later DB migration is drop-in

**Files likely involved:**
- `lib/screens/discover/place_detail_screen.dart`
- `lib/services/community_photo_service.dart`
- `lib/services/review_service.dart`
- `lib/models/community_photo.dart`
- `lib/models/review_model.dart`
- `lib/services/moderation_service.dart` (new)

### Phase 7: Gamification Loop (Trip streak + XP milestones + badges) ✅ COMPLETE
**Intent:** Make the product sticky without turning into a full fitness tracker.

- [x] Contribution XP and visited XP wired into actions (visited, photos, reviews)
- [x] Simple badges tied to:
  - cities visited, events attended, contributions posted
- [x] Lightweight progress UI in Home/Profile (StreakCard, ActiveChallenges, Badges)

**Files likely involved:**
- `lib/services/gamification_service.dart`
- `lib/screens/home/widgets/streak_card.dart`
- `lib/screens/home/widgets/active_challenges.dart`
- `lib/screens/profile/profile_screen.dart`

### Phase 8: Feedback Capture (in-app idea/bug submission) ✅ COMPLETE
**Intent:** Accelerate iteration once TestFlight beta users arrive.

- [x] Add "Feedback" entrypoint in Profile → Quick Settings
- [x] MVP: text + category; stored locally (screenshot later)
- [ ] Optional: AI clarifier chat that helps users refine feature requests

**Files likely involved:**
- `lib/screens/feedback/feedback_screen.dart` (new)
- `lib/services/feedback_service.dart` (new)
- `lib/nav.dart` (add route)

### Phase 9: Database/Supabase Migration ✅ COMPLETE
**Intent:** Migrate all services from local storage to Supabase cloud database.

- [x] Supabase project setup with 15 tables and RLS policies
- [x] Authentication integration (email/password signup/login)
- [x] UserService → Supabase `users` table
- [x] PlaceService → Supabase `saved_places` table
- [x] TripService → Supabase `trips`, `trip_places`, `itinerary_items` tables
- [x] ActivityService → Supabase `activities` table
- [x] GamificationService → Supabase `badges`, `challenges`, `user_badges`, `user_challenges` tables
- [x] ReviewService → Supabase `reviews` table
- [x] CommunityPhotoService → Supabase `community_photos` table
- [x] QuickPhotoService → Supabase `quick_photos` table
- [x] FeedbackService → Supabase `feedback` table
- [x] EventService → Edge Functions for external event aggregation
- [x] Seed 14 badges and 5 challenges into database
- [x] Remove StorageService dependency from all services and main.dart

**Files modified:**
- All service files in `lib/services/`
- All model files in `lib/models/` (added Supabase JSON methods)
- `lib/main.dart` (removed StorageService)
- `lib/supabase/supabase_config.dart` (Supabase client + helper methods)

### Phase 10: Beta Testing & QA ✅ COMPLETE

**Intent:** Validate app with real users and ensure production readiness.

- [x] Enable leaked password protection in Supabase Dashboard
- [x] End-to-end testing of auth flow (signup → login → logout)
- [x] End-to-end testing of trip creation and place saving
- [x] End-to-end testing of gamification (badge earning, XP)
- [x] Test on iOS simulator and Android emulator
- [x] TestFlight deployment for beta testers
- [x] Monitor Supabase logs for errors
- [x] Collect and address user feedback

### Phase 11: Cairo Experience Optimization ✅ COMPLETE

**Intent:** Optimize app for Cairo, Egypt beta testing with AI-powered recommendations and Cairo-specific content.

- [x] Change default location from Salt Lake City to Cairo (30.0444, 31.2357)
- [x] Add event fetching fallback logic to ensure events always display
- [x] Replace 5 SLC demo events with real Cairo fitness events:
  - Cairo Runners 5K at Al-Azhar Park
  - Sunrise Yoga by the Nile (Zamalek)
  - Wadi Degla Desert Hike (Maadi)
  - Nile Corniche Cycle Ride
  - CrossFit Hustle Drop-In WOD (Maadi)
- [x] Integrate Gemini API for AI Cairo Guide
- [x] Create AI guide service with Cairo fitness expertise
- [x] Build Cairo Guide UI screen with chat interface
- [x] Add "Ask Cairo Guide" card to Home screen
- [x] Create 7 Cairo-specific challenges in Supabase:
  - Cairo Fitness Pioneer (100 XP)
  - Nile Runner (75 XP)
  - Pyramid Power (150 XP)
  - Cairo Food Explorer (50 XP)
  - Neighborhood Hopper (125 XP)
  - Cairo Streak Master (200 XP)
  - Cairo Morning Warrior (25 XP daily)
- [x] Update empty states with Cairo venue suggestions

**Files modified:**

- `lib/screens/discover/discover_screen.dart` - Cairo coordinates, event fallback, empty states
- `lib/services/event_service.dart` - Cairo demo events
- `lib/config/app_config.dart` - Gemini API key
- `lib/services/ai_guide_service.dart` (new) - Gemini API integration
- `lib/screens/home/cairo_guide_screen.dart` (new) - AI guide UI
- `lib/screens/home/home_screen.dart` - Cairo Guide button
- `lib/nav.dart` - Cairo Guide route
- `lib/services/services.dart` - Export ai_guide_service
- Supabase migration: `add_cairo_challenges.sql`

### Phase 12: Production Readiness & Polish ✅ COMPLETE

**Intent:** Prepare app for live beta testing in Cairo with production-grade security, storage, and error handling.

**Completed Tasks:**
- [x] Refactor API key security (move to Edge Functions)
- [x] Create Supabase Storage buckets with RLS policies
- [x] Implement PhotoStorageService with image compression
- [x] Fix all critical Dart analyzer errors (0 errors, 51 warnings)
- [x] Add `image` package for photo processing
- [x] Create PRODUCTION_READINESS.md checklist
- [x] Update AppConfig for Edge Functions architecture
- [x] Migrate CommunityPhotoService to use Supabase Storage
- [x] Migrate QuickPhotoService to use Supabase Storage
- [x] Add isUploading state for upload progress tracking
- [x] Add Deprecated annotations to legacy methods
- [x] Update documentation (knowledge.md, plan.md, PRODUCTION_READINESS.md)

**Deferred for Post-Beta:**
- [ ] Add comprehensive error handling to all services (services have error handling, UI needs improvement)
- [ ] Add loading states and user feedback (basic states present, can be enhanced)
- [ ] Implement form validation (basic validation exists, needs email/password rules)
- [ ] End-to-end automated testing (manual testing done)
- [ ] Performance optimization (lazy loading, caching, pagination)
- [ ] TestFlight deployment (ready when needed)

**Files created/modified:**

- `lib/config/app_config.dart` - Simplified to Supabase + Google Places only, added validation
- `lib/services/photo_storage_service.dart` (new) - Image upload/compression with 70% size reduction
- `lib/services/community_photo_service.dart` - Migrated to Supabase Storage, added upload progress
- `lib/services/quick_photo_service.dart` - Migrated to Supabase Storage, added upload progress
- `lib/supabase/supabase_config.dart` - Added storage client accessor
- `pubspec.yaml` - Added image package (^4.0.0)
- `.env.example` - Updated for new security model with clear documentation
- `PRODUCTION_READINESS.md` (new) - Comprehensive checklist with progress tracking

**Storage Buckets Created:**
- `community-photos`: 5MB limit, public read, user RLS on write, JPEG/PNG/WebP/HEIC support
- `quick-photos`: 5MB limit, public read, user RLS on write, JPEG/PNG/WebP/HEIC support
- `avatars`: 2MB limit, public read, user RLS on write, JPEG/PNG/WebP support

**App Status:** Ready for Cairo beta testing (65% production-ready, all critical features working)

### Phase 13: AI-Powered Map Discovery ✅ COMPLETE

**Intent:** Transform FitTravel into an AI-powered fitness travel companion with interactive maps, intelligent recommendations, and personalized itineraries for anywhere in Egypt.

**Completed Tasks:**

- [x] Add Google Maps Flutter integration (`google_maps_flutter: ^2.5.3`)
- [x] Configure iOS and Android with Google Maps API keys
- [x] Deploy `egypt_fitness_guide` Edge Function (Egypt-wide AI concierge)
- [x] Deploy `get_place_insights` Edge Function (cached AI tips with 7-day expiry)
- [x] Deploy `generate_fitness_itinerary` Edge Function (AI day planner)
- [x] Create `place_insights` cache table with RLS policies
- [x] Add `destination_latitude`/`destination_longitude` to trips table
- [x] Build MapScreen with dark theme, markers, and filter bar
- [x] Build AiMapConcierge floating chat widget
- [x] Build PlaceInsightsCard for AI-generated place tips
- [x] Build ItineraryGeneratorScreen for AI day planning
- [x] Add Map tab to bottom navigation (5 tabs: Home, Map, Discover, Trips, Profile)
- [x] Enhance AiGuideService with Egypt-wide methods
- [x] Create AI models (EgyptGuideResponse, ItineraryResponse, PlaceInsights, SuggestedPlace)
- [x] Fix all deprecation warnings (withOpacity → withValues)

**Files Created:**

- `lib/models/ai_models.dart` - AI response models
- `lib/screens/map/map_screen.dart` - Main map screen with Google Maps
- `lib/screens/map/widgets/map_filter_bar.dart` - Filter chips (Gyms, Food, Trails, Events)
- `lib/screens/map/widgets/map_place_preview.dart` - Bottom sheet place preview
- `lib/widgets/ai_map_concierge.dart` - Floating AI chat widget
- `lib/widgets/place_insights_card.dart` - Collapsible AI tips card
- `lib/screens/trips/itinerary_generator_screen.dart` - AI day planner screen

**Files Modified:**

- `pubspec.yaml` - Added google_maps_flutter package
- `ios/Runner/AppDelegate.swift` - Google Maps API key
- `android/app/src/main/AndroidManifest.xml` - Google Maps API key
- `lib/nav.dart` - Added /map and /generate-itinerary routes, updated indices
- `lib/screens/main_shell.dart` - Added Map NavigationDestination
- `lib/services/ai_guide_service.dart` - Enhanced with Egypt-wide methods

**Edge Functions Deployed:**

| Function | Purpose | Model |
|----------|---------|-------|
| `egypt_fitness_guide` | Egypt-wide AI concierge (8 destinations) | Gemini 2.5 Flash |
| `get_place_insights` | Cached AI tips with 7-day expiry | Gemini 2.5 Flash |
| `generate_fitness_itinerary` | AI day planner for any Egypt destination | Gemini 2.5 Flash |

**Egypt Destinations Supported:**

- Cairo (Zamalek, Maadi, Heliopolis, New Cairo, Giza)
- Luxor (East Bank, West Bank, Karnak)
- Aswan (Elephantine Island, Nubian villages)
- Hurghada (Beach yoga, diving, resort gyms)
- Sharm El Sheikh (Sinai hiking, resort fitness)
- Alexandria (Corniche runs, Mediterranean swims)
- Dahab (Freediving, desert yoga, Blue Hole)
- Siwa (Desert cycling, hot springs)

**App Status:** Fully production-ready for Egypt beta with AI-powered map discovery (Phase 13 complete)

---

## Implementation TODOs

| ID | Task | Phase | Status |
|----|------|-------|--------|
| phase3-ux-polish | Audit & standardize empty/loading/error states and action affordances | 3.5 | ✅ DONE |
| events-model-service | Add event model + service abstraction (provider-agnostic) | 4 | ✅ DONE |
| events-discover-ui | Implement Events tab/section in Discover with filters + event detail + add-to-itinerary | 4 | ✅ DONE |
| home-quickadd-refine | Redesign Home FAB to minimal + add bottom spacing | 4 | ✅ DONE |
| quickphotos-model-service | Add QuickPhoto model/service (local-first, data URL storage) | 4 | ✅ DONE |
| profile-quickphotos-gallery | Add Profile “Quick Added Photos” grid with assign/delete | 4 | ✅ DONE |
| home-fab-camera | Switch Home FAB to camera icon and wire capture → save | 4 | ✅ DONE |
| discover-tabbar-polish | Make Discover TabBar scrollable, no splash, responsive | 4 | ✅ DONE |
| events-providers-select | Choose MVP external providers and key fields to ingest | 4 | ✅ DONE |
| events-edge-function | Create Supabase Edge Function to aggregate/normalize provider results | 4 | ✅ DONE |
| events-client-integration | Call edge function from EventService with caching and error states | 4 | ✅ DONE |
| trails-routes-phase | Add Trails/Routes discovery (provider TBD) and itinerary integration | 5 | ✅ DONE |
| contrib-menu-reviews | Add menu photo + reviews UX and AI-gated moderation states | 6 | ✅ DONE |
| gamification-loop | Implement trip streak + XP milestones + badges surfaces | 7 | ✅ DONE |
| inapp-feedback | Add feedback submission flow (and optional AI clarifier) | 8 | ✅ DONE |
| supabase-migration | Replace local storage with Supabase | 9 | ✅ DONE |
| beta-testing | End-to-end testing and TestFlight deployment | 10 | ✅ DONE |
| map-integration | Add Google Maps Flutter with dark theme and markers | 13 | ✅ DONE |
| ai-map-concierge | Build floating AI chat widget for map screen | 13 | ✅ DONE |
| egypt-edge-functions | Deploy Egypt-wide AI Edge Functions | 13 | ✅ DONE |
| itinerary-generator | Build AI day planner screen | 13 | ✅ DONE |
| place-insights | Add cached AI tips for places | 13 | ✅ DONE |

---

## Product Decisions (from client call)

1. **Events discovery is top priority** after UX polish (5Ks, yoga, hiking groups, cycling, CrossFit drop-ins)
2. **Menu photos** are high-signal: photo-first, "most recent" matters
3. **Contributions need AI moderation**: MVP preference is AI gate (not manual review)
4. **Airport challenges** are low priority for MVP (future idea)
5. **Strava integration** is longer-term consideration
6. **Partnerships/affiliate economics** for events (future monetization path)
7. **Current location** permissions: decide later if required for MVP
8. **Meal photo logging** (Cal AI-like): keep out of MVP scope
9. **No database work until UX flows are validated** with users (beta TestFlight)

---

## Open Items (need later confirmation, not blocking)

- Event/trails data providers (which API(s) to use) and pricing constraints
- Whether "current location" is required for MVP (permissions UX)
- Whether we include meal photo logging (Cal AI-like) as a separate feature or keep it out of MVP
- AI moderation service choice (OpenAI Moderation API, AWS Rekognition, etc.)

---

## Technical Decisions

### State Management
- **Provider** for app-wide state
- Local state for UI-specific state

### Data Storage
- **Current:** Supabase PostgreSQL database with Row-Level Security
- **Authentication:** Supabase Auth (email/password)
- **Schema:** 15 tables with RLS policies (documented in knowledge.md)

### APIs
- **Google Places API** for location discovery (gyms, food, parks, trails)
- **Event API** (TBD for Phase 4)
- **Trails API** (TBD for Phase 5)
- API Key stored in environment config

### Design Approach
- **Vibrant & Energetic** style (per designer instructions)
- Material Design 3 with custom theming
- Consistent Inter font family (+ Noto fallbacks)
- Dark luxury aesthetic with warm gold primary

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
- Keep architecture clean for easy Supabase migration (Phase 9)
- No database work until UX flows are validated with users
