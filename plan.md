# FitTravel Development Plan

> **Current Phase:** Phase 4 - Events Discovery (In Progress)
> **Last Updated:** Current Session
> **Strategy:** UX-first MVP — hold DB until flows are proven

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

### Phase 4: Events Discovery 🚧 IN PROGRESS
**Intent:** Let users find **active lifestyle events** near a destination or current location and add them into trips.

- [x] Add `event_model.dart` and `event_service.dart`
- [x] Add **Events** surface to Discover (new tab)
- [x] Filters: date range, categories (running, yoga, hiking, cycling, CrossFit)
- [x] Event detail: location, time/date, website/registration, add-to-itinerary
- [x] Home FAB → camera-first Quick Add flow (saves to Quick Photos)
- [x] Profile → Quick Added Photos section (unassigned shots)
- [ ] Decide and implement MVP data sources:
  - Default: **external event API** (provider TBD) + fallback to curated search
  - Later: optional Strava API tie-in

**Files likely involved:**
- `lib/models/event_model.dart` (new)
- `lib/services/event_service.dart` (new)
- `lib/screens/discover/discover_screen.dart`
- `lib/screens/discover/event_detail_screen.dart` (new)

### Phase 5: Trails/Routes Discovery
**Intent:** Help travelers find good/safe runs/hikes without needing Strava-level infrastructure.

- [ ] Add `trail_model.dart` and `trail_service.dart`
- [ ] Add "Trails/Routes" discovery with:
  - Basic trail cards (distance, elevation if available, safety/lighting notes if available)
  - Save + add to itinerary
- [ ] Choose MVP source(s): Google Places (parks/trails) + a trails provider (TBD)

**Files likely involved:**
- `lib/models/trail_model.dart` (new)
- `lib/services/trail_service.dart` (new)
- `lib/screens/discover/discover_screen.dart`
- `lib/screens/discover/trail_detail_screen.dart` (new)

### Phase 6: Contributions v1 (Photos/Menu/Reviews + AI Moderation)
**Intent:** Unlock the community flywheel without a heavy admin workflow.

- [ ] Place detail: add **Menu** contributions (photo-first) + "last updated" label
- [ ] Add **Reviews** (short text + rating + quick prompts)
- [ ] AI-gated moderation (MVP spec):
  - Client-side pre-check UI states ("Checking…" → publish/reject)
  - Reject nudity/hate/spam; allow user **Report** action
- [ ] Store locally for now; design interfaces so later DB migration is drop-in

**Files likely involved:**
- `lib/screens/discover/place_detail_screen.dart`
- `lib/services/community_photo_service.dart`
- `lib/services/review_service.dart`
- `lib/models/community_photo.dart`
- `lib/models/review_model.dart`
- `lib/services/moderation_service.dart` (new)

### Phase 7: Gamification Loop (Trip streak + XP milestones + badges)
**Intent:** Make the product sticky without turning into a full fitness tracker.

- [ ] Trip streak (active trip days), contribution XP, visited XP
- [ ] Simple badges tied to:
  - cities visited, events attended, contributions posted
- [ ] Lightweight progress UI in Home/Profile

**Files likely involved:**
- `lib/services/gamification_service.dart`
- `lib/screens/home/widgets/streak_card.dart`
- `lib/screens/home/widgets/active_challenges.dart`
- `lib/screens/profile/profile_screen.dart`

### Phase 8: Feedback Capture (in-app idea/bug submission)
**Intent:** Accelerate iteration once TestFlight beta users arrive.

- [ ] Add "Feedback" entrypoint accessible globally
- [ ] MVP: text + screenshot attach later (optional)
- [ ] Optional: AI clarifier chat that helps users refine feature requests

**Files likely involved:**
- `lib/screens/feedback/feedback_screen.dart` (new)
- `lib/services/feedback_service.dart` (new)
- `lib/nav.dart` (add route)

### Phase 9: Database/Supabase Migration (Deferred)
**Intent:** Migrate only after flows are validated.

- [ ] Replace local storage with Supabase tables + storage
- [ ] Add admin tooling (web dashboard) after beta demand

**Files likely involved:**
- All service files (swap local storage for Supabase)
- `lib/config/supabase_config.dart` (new)

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
| events-providers-select | Choose MVP external providers and key fields to ingest | 4 | ⏳ PENDING |
| events-edge-function | Create Supabase Edge Function to aggregate/normalize provider results | 4 | ⏳ PENDING |
| events-client-integration | Call edge function from EventService with caching and error states | 4 | ⏳ PENDING |
| trails-routes-phase | Add Trails/Routes discovery (provider TBD) and itinerary integration | 5 | ⏳ PENDING |
| contrib-menu-reviews | Add menu photo + reviews UX and AI-gated moderation states | 6 | ⏳ PENDING |
| gamification-loop | Implement trip streak + XP milestones + badges surfaces | 7 | ⏳ PENDING |
| inapp-feedback | Add feedback submission flow (and optional AI clarifier) | 8 | ⏳ PENDING |
| supabase-migration | Replace local storage with Supabase | 9 | ⏳ DEFERRED |

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
- **Current:** SharedPreferences for local storage (JSON serialization)
- **Future (Phase 9):** Supabase (schema documented in knowledge.md)

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
