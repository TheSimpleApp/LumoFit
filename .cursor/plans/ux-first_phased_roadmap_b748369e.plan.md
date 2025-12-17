---
name: UX-first phased roadmap
overview: Update the roadmap to prioritize dialed-in mobile UX flows (no database yet), with Events discovery as the next major phase and AI-gated community contributions designed to migrate cleanly to a database later.
todos:
  - id: phase3-ux-polish
    content: Polish core UX across Discover/Place/Trips/Itinerary (empty/loading/error states, consistent actions, micro-interactions).
    status: pending
  - id: events-model-service
    content: Introduce provider-agnostic Events layer (model + service + adapter) so UI isn’t coupled to one API.
    status: pending
    dependencies:
      - phase3-ux-polish
  - id: events-discover-ui
    content: Add Events to Discover and Trip planning (filters, event detail, add-to-itinerary).
    status: pending
    dependencies:
      - events-model-service
  - id: trails-routes-phase
    content: Add Trails/Routes discovery and itinerary integration (data source TBD).
    status: completed
    dependencies:
      - events-discover-ui
  - id: contrib-menu-reviews
    content: Add menu photo + reviews UX on Place Detail with AI-gated moderation states; design for later DB migration.
    status: completed
    dependencies:
      - phase3-ux-polish
  - id: gamification-loop
    content: Implement trip streak + XP milestones + simple badges tied to visits/contributions/events.
    status: pending
    dependencies:
      - contrib-menu-reviews
  - id: inapp-feedback
    content: Add in-app feedback/ideas capture (text first; optional AI clarifier) for beta testers.
    status: pending
    dependencies:
      - phase3-ux-polish
---

# FitTravel UX-First Plan (No DB Yet)

## Goals (from latest client call)

- Ship a **buttery, mobile-first MVP** that works in the field while traveling: find gyms/food/events → take action (call/directions) → save/add to trip → mark visited → contribute (photos/menu/review) → light gamification.
- **Hold off on database/Supabase** until UX is proven. Keep all product decisions logged in `knowledge.md` and execution plan in `plan.md`.
- Prioritize **Events discovery** next (5Ks/yoga/etc), then expand into trails/routes and deeper gamification.

## Current baseline (already implemented)

- Discover (Gyms + Food) using Google Places
- Place detail (actions + save)
- Trips (create/edit, destination autocomplete, associate places)
- Itinerary editor + read-only trip activity timeline
- Community Photos (URL-based, local storage)

## Phased roadmap

### Phase 3.5 — UX/Polish Pass (lock the core flows)

**Intent:** make existing flows feel production-grade before adding net-new surfaces.

- Audit/standardize **empty states**, loading, error states across Discover/Place/Trips/Itinerary.
- Add micro-interactions: haptics, subtle transitions, consistent bottom sheets.
- Tighten IA labels and copy (e.g., “Visited”, “Add to Trip”, “Save”, “Directions”).
- Ensure “call/directions/website” actions are always reachable and consistent.

Files likely involved:

- `lib/screens/home/...`
- `lib/screens/discover/...`
- `lib/screens/trips/...`
- `lib/theme.dart`

### Phase 4 — Events (priority next)

**Intent:** let users find **active lifestyle events** near a destination or current location and add them into trips.

- Add **Events** surface to Discover (and optionally in Trip planning):
- Filters: date range, distance radius, categories (5K/10K/half/full, yoga, hiking group, cycling, CrossFit drop-in events if available)
- Event detail: location, time/date, website/registration, add-to-itinerary.
- Decide and implement MVP data sources:
- Default: **external event API** (provider TBD) + fallback to curated search.
- Later: optional Strava API tie-in.

Files likely involved:

- `lib/screens/discover/discover_screen.dart`
- `lib/services/...` (new `events_service.dart`)
- `lib/models/...` (new `event_model.dart`)

### Phase 5 — Trails/Routes (Strava-like “safe run/hike” discovery)

**Intent:** help travelers find good/safe runs/hikes without needing Strava-level infrastructure.

- Add “Trails/Routes” discovery with:
- Basic trail cards (distance, elevation if available, safety/lighting notes if available)
- Save + add to itinerary
- Choose MVP source(s): Google Places (parks/trails) + a trails provider (TBD).

### Phase 6 — Contributions v1 (Photos/Menu/Reviews) with AI-gated moderation

**Intent:** unlock the community flywheel without a heavy admin workflow.

- Place detail: add **Menu** contributions (photo-first) + “last updated” label.
- Add **Reviews** (short text + rating + quick prompts).
- AI-gated moderation (MVP spec):
- Client-side pre-check UI states (“Checking…” → publish/reject)
- Reject nudity/hate/spam; allow user **Report** action.
- Store locally for now; design interfaces so later DB migration is drop-in.

Files likely involved:

- `lib/screens/discover/place_detail_screen.dart`
- `lib/services/community_photo_service.dart`
- `lib/services/review_service.dart`
- `lib/models/community_photo.dart`, `lib/models/review_model.dart`

### Phase 7 — Gamification loop (Trip streak + XP milestones + badges)

**Intent:** make the product sticky without turning into a full fitness tracker.

- Trip streak (active trip days), contribution XP, visited XP.
- Simple badges tied to:
- cities visited, events attended, contributions posted
- Lightweight progress UI in Home/Profile.

Files likely involved:

- `lib/services/gamification_service.dart`
- `lib/screens/home/widgets/...`
- `lib/screens/profile/profile_screen.dart`

### Phase 8 — Feedback capture (in-app idea/bug submission)

**Intent:** accelerate iteration once TestFlight beta users arrive.

- Add “Feedback” entrypoint accessible globally.
- MVP: text + screenshot attach later (optional).
- Optional: AI clarifier chat that helps users refine feature requests.

### Phase 9 — Database/Supabase (deferred until UX is proven)

**Intent:** migrate only after flows are validated.

- Replace local storage with Supabase tables + storage.
- Add admin tooling (web dashboard) after beta demand.

## Product decisions logged from the transcript (to add to `knowledge.md`)

- Events discovery is a top value prop (5Ks/yoga/etc) and should integrate with trip planning.
- Menus are a high-signal need: photo-first, “most recent” matters.
- Contributions need moderation: MVP preference is **AI gate**.
- Airport challenges are low priority for MVP; keep as future idea.
- Longer-term: Strava integration, partnerships/affiliate economics for events.

## Open items (need later confirmation, but not blocking the plan)

- Event/trails data providers (which API(s) to use) and pricing constraints.
- Whether “current location” is required for MVP (permissions UX).
- Whether we include meal photo logging (Cal AI-like) as a separate feature or keep it out of MVP.

## Implementation todos

- **phase3-ux-polish**: Audit & standardize empty/loading/error states and action affordances across core flows
- **events-model-service**: Add event model + service abstraction (provider-agnostic)
- **events-discover-ui**: Implement Events tab/section in Discover with filters + event detail + add-to-itinerary
- **trails-routes-phase**: Add Trails/Routes discovery (provider TBD) and itinerary integration
- **contrib-menu-reviews**: Add menu photo + reviews UX and AI-gated moderation states
- **gamification-loop**: Implement trip streak + XP milestones + badges surfaces
- **inapp-feedback**: Add feedback submission flow (and optional AI clarifier)