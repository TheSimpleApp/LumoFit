# FitTravel Development Plan

> **Current Phase:** Phase 10 - Beta Testing & QA
> **Last Updated:** December 2024
> **Strategy:** Cloud-synced MVP ready for live beta testing

---

## Goals (from latest client call)

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

### Phase 10: Beta Testing & QA (CURRENT)
**Intent:** Validate app with real users and ensure production readiness.

- [ ] Enable leaked password protection in Supabase Dashboard
- [ ] End-to-end testing of auth flow (signup → login → logout)
- [ ] End-to-end testing of trip creation and place saving
- [ ] End-to-end testing of gamification (badge earning, XP)
- [ ] Test on iOS simulator and Android emulator
- [ ] TestFlight deployment for beta testers
- [ ] Monitor Supabase logs for errors
- [ ] Collect and address user feedback

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
| beta-testing | End-to-end testing and TestFlight deployment | 10 | ⏳ IN PROGRESS |

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
