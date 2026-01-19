# CONTEXT.md - LumoFit Business Requirements

> **Document Purpose:** Business context and requirements for AI coding assistants
> **Last Updated:** January 19, 2026
> **Current Sprint:** Door to Door Con (D2D Con) Demo

---

## 🎯 Product Vision

**LumoFit** (formerly FitTravel) is a premium, free-to-use fitness travel lifestyle app that eliminates every excuse for staying healthy while traveling.

### Core Value Proposition
1. **Discover** - Find gyms, healthy food, trails, and fitness events anywhere
2. **Take Action** - Call, get directions, save for later
3. **Track** - Mark places visited, contribute photos/reviews
4. **Engage** - Light gamification to keep users motivated

### Target Users
- Health-conscious travelers
- Business travelers wanting to maintain routines
- Fitness enthusiasts exploring new cities
- Anyone who wants to stay active while away from home

---

## 📅 Current Sprint: D2D Con Demo

### Context (from Jan 13, 2026 meeting with JC Chanowsky)

**Event:** Door to Door Con
**Timeline:** ~8 days from meeting (Demo around Jan 21, 2026)
**Goal:** Public TestFlight beta for select conference attendees

### Key Decisions from Meeting

#### What to Focus On
1. **Map Tab** - The hero feature
   - Color-coded pins by place type
   - Quick location search without trip creation
   - Distance filters

2. **Discover Tab** - Visual appeal
   - Photo carousel in place cards
   - Better visual hierarchy
   - Smooth animations

3. **Saved Locations** - Simplified saving
   - Quick save without creating a trip
   - Albums/categories for organization
   - Grid view with photo-first cards

#### What to Remove/Hide
1. **Challenges** - Too complex for demo
2. **Log Activity** - Unnecessary for discovery focus
3. **Complex Trip Planner** - Keep trips simple or hide
4. **Cairo Guide** - Egypt-specific, not relevant
5. **Gamification XP** - Distraction from core value

#### What to Keep
1. **Events** - Want user feedback on this feature
2. **Basic profile** - Simplified version
3. **Saved places** - Core functionality

### Success Criteria
- [ ] App doesn't crash on launch
- [ ] Map loads with color-coded markers
- [ ] Users can search and discover places
- [ ] Users can save places without friction
- [ ] TestFlight public link works
- [ ] Positive first impression at demo

---

## 🏗️ Technical Context

### Current Architecture
- **Frontend:** Flutter 3.6+ / Dart
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **Maps:** Google Maps Flutter SDK
- **AI:** Gemini 2.5 Flash via Edge Functions
- **State:** Provider pattern

### Key Technical Decisions
1. **Provider over Riverpod** - Already established, don't change mid-sprint
2. **GoRouter for navigation** - Clean URL-based routing
3. **Supabase Edge Functions** - Keep API keys secure, AI processing server-side
4. **Dark luxury theme** - Established brand, gold accents

### Database Tables (Supabase)
- `users` - User profiles
- `trips` - Trip metadata
- `saved_places` - Bookmarked locations
- `activities` - User actions log
- `badges` - Achievement definitions
- `challenges` - Challenge definitions
- `community_photos` - User-uploaded photos
- `reviews` - Place reviews
- `events` - Fitness events
- `trails` - Trail/route data

---

## 👥 Team & Communication

### Stakeholders
- **JC Chanowsky** - Product direction, design feedback
- **Mikko Paulino** - Technical input
- **David Dotson** - Development lead

### Communication Channels
- **Slack** - Primary async communication
- **Fireflies** - Meeting transcripts for context
- **GitHub** - Code, PRs, issues

### Meeting Cadence
- Standups as needed via Slack
- Ad-hoc calls for blockers
- Demo at D2D Con

---

## 📊 Metrics (Post-Launch)

### Engagement Metrics
- Daily active users (DAU)
- Places discovered per session
- Save rate (views → saves)
- Return rate (7-day retention)

### Feature Metrics
- Map interactions per session
- Search queries performed
- Events clicked/registered
- Photos uploaded

### Quality Metrics
- App crash rate
- API response times
- User-reported bugs

---

## 🎨 Brand Guidelines

### App Name
- **Official:** LumoFit
- **Formerly:** FitTravel

### Visual Identity
- **Theme:** Dark luxury aesthetic
- **Primary:** Gold/warm accent colors
- **Background:** Dark grays (#121212, #1E1E1E)
- **Typography:** Clean, modern, readable

### Tone of Voice
- Encouraging but not pushy
- Premium but accessible
- Health-focused but not preachy
- Travel-savvy and worldly

---

## 📝 Feature Requirements

### Map Tab (Priority 1)
**User Story:** As a traveler, I want to see fitness-related places on a map so I can quickly find what's nearby.

**Requirements:**
- Display Google Map centered on user location (or searched location)
- Show markers for gyms, food, trails, events
- Color-code markers by type for quick scanning
- Tap marker to see preview card
- Tap preview to open full details
- Filter markers by type and distance

### Discover Tab (Priority 1)
**User Story:** As a user, I want to browse places in a list format with rich previews.

**Requirements:**
- List of places with photo, name, type, distance, rating
- Category tabs (Gyms, Food, Trails, Events)
- Pull to refresh
- Tap to open place detail
- Photos should be prominently displayed

### Saved Locations (Priority 2)
**User Story:** As a user, I want to save places I'm interested in without friction.

**Requirements:**
- One-tap save from place card or detail
- Saved places accessible in Profile
- Optional: Organize into albums/categories
- View saved places as grid with photos

### Events (Priority 2)
**User Story:** As a fitness enthusiast, I want to find local events like 5Ks and yoga classes.

**Requirements:**
- List of upcoming events in area
- Event detail with date, location, registration link
- Filter by event type
- Add to calendar (stretch goal)

---

## 🚫 Out of Scope (D2D Sprint)

1. **User accounts/auth** - Works, but don't enhance
2. **Complex gamification** - XP, badges, challenges
3. **Social features** - Sharing, friends, leaderboards
4. **Offline mode** - Nice to have, not critical
5. **Push notifications** - Future enhancement
6. **Trip itinerary builder** - Too complex for demo
7. **AI concierge chat** - Egypt-specific, hide for now
8. **Photo contributions** - Works, but don't highlight
9. **Reviews** - Works, but secondary

---

## 🔗 Related Documents

- `AGENT.md` - AI coding guidelines
- `PLAN.md` - Sprint tasks and checklists
- `knowledge.md` - Full technical documentation
- `.cursor/rules` - Cursor-specific rules
