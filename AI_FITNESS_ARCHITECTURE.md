# AI Fitness Intelligence - Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERFACE                            │
│                   (Place Detail Screen)                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ 1. Opens Place Details
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PlaceDetailScreen                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  State:                                                   │  │
│  │  - _fitnessIntel: PlaceFitnessIntelligence?             │  │
│  │  - _isLoadingIntel: bool                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                    │
│                             │ 2. Calls _loadFitnessIntelligence()│
│                             ▼                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Gathers Context:                                         │  │
│  │  - Community reviews (ReviewService)                      │  │
│  │  - Place data (name, type, rating, etc.)                 │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ 3. Calls analyzePlaceFitness()
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AiGuideService                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  analyzePlaceFitness({                                    │  │
│  │    placeId, placeName, placeType,                        │  │
│  │    reviews, placeData                                     │  │
│  │  })                                                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                    │
│                             │ 4. Invokes Edge Function           │
│                             ▼                                    │
└─────────────────────────────────────────────────────────────────┘
                             │
                             │ HTTP POST
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              SUPABASE EDGE FUNCTION                              │
│           (analyze_place_fitness)                                │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Step 1: Check Cache                                        │ │
│  │ ┌────────────────────────────────────────────────────────┐ │ │
│  │ │ SELECT * FROM place_fitness_intelligence_cache         │ │ │
│  │ │ WHERE place_id = ? AND created_at > NOW() - 24 hours  │ │ │
│  │ └────────────────────────────────────────────────────────┘ │ │
│  │                        │                                    │ │
│  │           ┌────────────┴────────────┐                      │ │
│  │           ▼                         ▼                      │ │
│  │      Cache Hit                  Cache Miss                │ │
│  │    (Return cached)           (Continue to AI)             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                     │                            │
│                                     │ 5. Call Gemini API         │
│                                     ▼                            │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Step 2: Build Prompt                                       │ │
│  │ ┌────────────────────────────────────────────────────────┐ │ │
│  │ │ - Place name, type                                     │ │ │
│  │ │ - Community reviews                                    │ │ │
│  │ │ - Place data (rating, price, hours)                   │ │ │
│  │ │ - Type-specific fields (gym/restaurant/trail)         │ │ │
│  │ └────────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                     │                            │
│                                     ▼                            │
└─────────────────────────────────────────────────────────────────┘
                                     │
                                     │ 6. API Request
                                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GOOGLE GEMINI API                             │
│                  (gemini-2.0-flash-exp)                          │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ AI Processing:                                             │ │
│  │ - Analyze reviews for fitness insights                     │ │
│  │ - Extract equipment, amenities, healthy options            │ │
│  │ - Determine best times and crowd patterns                  │ │
│  │ - Generate pros, cons, tips                                │ │
│  │ - Calculate fitness score                                  │ │
│  │ - Perform sentiment analysis                               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                     │                            │
│                                     │ 7. Return JSON             │
│                                     ▼                            │
└─────────────────────────────────────────────────────────────────┘
                                     │
                                     │ 8. Parse Response
                                     ▼
┌─────────────────────────────────────────────────────────────────┐
│              EDGE FUNCTION (continued)                           │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Step 3: Parse & Cache                                      │ │
│  │ ┌────────────────────────────────────────────────────────┐ │ │
│  │ │ - Parse JSON response                                  │ │ │
│  │ │ - Validate structure                                   │ │ │
│  │ │ - Add metadata (timestamp, review count)              │ │ │
│  │ └────────────────────────────────────────────────────────┘ │ │
│  │                        │                                    │ │
│  │                        ▼                                    │ │
│  │ ┌────────────────────────────────────────────────────────┐ │ │
│  │ │ INSERT INTO place_fitness_intelligence_cache           │ │ │
│  │ │ (place_id, intelligence, reviews_analyzed, ...)        │ │ │
│  │ └────────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                     │                            │
│                                     │ 9. Return to Client        │
│                                     ▼                            │
└─────────────────────────────────────────────────────────────────┘
                                     │
                                     │ 10. Response
                                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AiGuideService                                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Parse PlaceFitnessIntelligence from JSON                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                     │                            │
│                                     │ 11. Return to Screen       │
│                                     ▼                            │
└─────────────────────────────────────────────────────────────────┘
                                     │
                                     │ 12. Update State
                                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                   PlaceDetailScreen                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ setState(() {                                              │ │
│  │   _fitnessIntel = intelligence;                           │ │
│  │   _isLoadingIntel = false;                                │ │
│  │ })                                                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                     │                            │
│                                     │ 13. Render UI              │
│                                     ▼                            │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ PlaceFitnessIntelligenceCard                              │ │
│  │ ├─ Fitness Score Badge                                    │ │
│  │ ├─ AI Summary                                             │ │
│  │ ├─ Type-Specific Insights                                 │ │
│  │ │  ├─ GymInsightsSection                                  │ │
│  │ │  ├─ RestaurantInsightsSection                           │ │
│  │ │  └─ TrailInsightsSection                                │ │
│  │ ├─ Pros & Cons                                            │ │
│  │ └─ Sentiment Chip                                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ QuickInsightsChips                                        │ │
│  │ ├─ Best Time Badge                                        │ │
│  │ ├─ Crowd Level Badge                                      │ │
│  │ └─ Feature Badges                                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ SmartTimingWidget                                         │ │
│  │ ├─ Morning/Evening Times                                  │ │
│  │ └─ Crowd Insights                                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Additional Sections                                       │ │
│  │ ├─ AI Tips                                                │ │
│  │ ├─ What to Bring                                          │ │
│  │ └─ Common Phrases                                         │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Request Flow
```
User Action → Screen State → Service Call → Edge Function → AI API
```

### Response Flow
```
AI API → Edge Function → Cache → Service → Screen State → UI Render
```

## Caching Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                    CACHE DECISION TREE                           │
└─────────────────────────────────────────────────────────────────┘

Request for Place Intelligence
        │
        ▼
   Check Cache
        │
        ├─────────────┬─────────────┐
        ▼             ▼             ▼
   Entry Exists   No Entry    Entry Expired
   (< 24h old)                (> 24h old)
        │             │             │
        ▼             ▼             ▼
   CACHE HIT    CACHE MISS    CACHE MISS
        │             │             │
        │             └─────┬───────┘
        │                   │
        │                   ▼
        │            Call Gemini API
        │                   │
        │                   ▼
        │            Parse Response
        │                   │
        │                   ▼
        │            Update Cache
        │                   │
        └─────────┬─────────┘
                  │
                  ▼
           Return Intelligence
```

## Component Hierarchy

```
PlaceDetailScreen
├─ AppBar (existing)
├─ Hero Image (existing)
├─ Place Info (existing)
├─ Quick Actions (existing)
├─ [NEW] Loading Indicator (conditional)
└─ [NEW] AI Intelligence Section
    ├─ PlaceFitnessIntelligenceCard
    │   ├─ Header (icon + title + score)
    │   ├─ Summary Text
    │   ├─ Sentiment Chip
    │   ├─ Type-Specific Section
    │   │   ├─ GymInsightsSection
    │   │   ├─ RestaurantInsightsSection
    │   │   └─ TrailInsightsSection
    │   └─ Pros & Cons Section
    ├─ QuickInsightsChips
    │   ├─ Best Time Chip
    │   ├─ Crowd Level Chip
    │   └─ Feature Chips
    ├─ SmartTimingWidget
    │   ├─ Time Slots
    │   └─ Crowd Insights
    ├─ AI Tips Section
    │   └─ Tip Cards
    ├─ What to Bring Section
    │   └─ Item Chips
    └─ Common Phrases Section
        └─ Phrase Chips
```

## Database Schema

```
┌────────────────────────────────────────────────────────────────┐
│      place_fitness_intelligence_cache                          │
├────────────────────────────────────────────────────────────────┤
│ id                  UUID (PK)                                  │
│ place_id            TEXT (indexed)                             │
│ place_name          TEXT                                       │
│ place_type          TEXT                                       │
│ intelligence        JSONB ◄──────────────────┐                │
│ reviews_analyzed    INTEGER                   │                │
│ created_at          TIMESTAMPTZ (indexed)     │                │
│ updated_at          TIMESTAMPTZ               │                │
└────────────────────────────────────────────────────────────────┘
                                                 │
                                                 │
                    ┌────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────────────────┐
│              JSONB Structure (intelligence)                    │
├────────────────────────────────────────────────────────────────┤
│ {                                                              │
│   "summary": "string",                                         │
│   "fitnessScore": 7.5,                                         │
│   "bestTimesDetailed": { "morning": "...", "evening": "..." },│
│   "crowdInsights": "string",                                   │
│   "gymInsights": { ... },        ◄─── Type-specific           │
│   "restaurantInsights": { ... }, ◄─── (one of these)          │
│   "trailInsights": { ... },      ◄─── based on place type     │
│   "pros": ["...", "..."],                                      │
│   "cons": ["...", "..."],                                      │
│   "tips": ["...", "..."],                                      │
│   "whatToBring": ["...", "..."],                               │
│   "sentiment": {                                               │
│     "overall": 0.7,                                            │
│     "label": "Positive",                                       │
│     "aspectScores": { "cleanliness": 0.8 }                     │
│   },                                                           │
│   "commonPhrases": ["...", "..."],                             │
│   "generatedAt": "2024-12-18T...",                             │
│   "reviewsAnalyzed": 15                                        │
│ }                                                              │
└────────────────────────────────────────────────────────────────┘
```

## Performance Characteristics

### Timing Breakdown

```
Total User-Perceived Time: 1-3 seconds

┌─────────────────────────────────────────────────────────────┐
│                    FIRST VISIT (Cache Miss)                  │
├─────────────────────────────────────────────────────────────┤
│ Screen Load          │ ▓▓░░░░░░░░░░░░░░░░░░░░░░ │ 100ms    │
│ Gather Context       │ ░░▓░░░░░░░░░░░░░░░░░░░░░ │ 50ms     │
│ Edge Function Call   │ ░░░▓░░░░░░░░░░░░░░░░░░░░ │ 100ms    │
│ Cache Check          │ ░░░░▓░░░░░░░░░░░░░░░░░░░ │ 50ms     │
│ Gemini API Call      │ ░░░░░▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░ │ 1200ms   │
│ Parse & Cache        │ ░░░░░░░░░░░░░░░░▓░░░░░░ │ 100ms    │
│ Return to Client     │ ░░░░░░░░░░░░░░░░░▓░░░░░ │ 100ms    │
│ UI Render            │ ░░░░░░░░░░░░░░░░░░▓░░░░ │ 50ms     │
├─────────────────────────────────────────────────────────────┤
│ TOTAL                │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ~1.75s   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   SUBSEQUENT VISIT (Cache Hit)               │
├─────────────────────────────────────────────────────────────┤
│ Screen Load          │ ▓▓▓░░░░░░░░░░░░░░░░░░░░ │ 100ms    │
│ Gather Context       │ ░░░▓▓░░░░░░░░░░░░░░░░░░ │ 50ms     │
│ Edge Function Call   │ ░░░░░▓▓░░░░░░░░░░░░░░░░ │ 100ms    │
│ Cache Hit            │ ░░░░░░░▓▓░░░░░░░░░░░░░░ │ 100ms    │
│ Return to Client     │ ░░░░░░░░░▓▓░░░░░░░░░░░░ │ 100ms    │
│ UI Render            │ ░░░░░░░░░░░▓░░░░░░░░░░░ │ 50ms     │
├─────────────────────────────────────────────────────────────┤
│ TOTAL                │ ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░ │ ~500ms   │
└─────────────────────────────────────────────────────────────┘
```

### Cost Analysis

```
┌─────────────────────────────────────────────────────────────┐
│                      COST BREAKDOWN                          │
├─────────────────────────────────────────────────────────────┤
│ Gemini API (per call)     │ $0.001                          │
│ Cache Hit Rate            │ 95%                             │
│ Effective Cost per View   │ $0.00005                        │
│                           │                                  │
│ Monthly Estimates:        │                                  │
│ - 500 unique places       │ $0.50 (initial analysis)        │
│ - 10,000 views            │ $0.50 (cache misses)            │
│ - Total                   │ $1.00/month                     │
└─────────────────────────────────────────────────────────────┘
```

## Error Handling

```
┌─────────────────────────────────────────────────────────────┐
│                    ERROR FLOW                                │
└─────────────────────────────────────────────────────────────┘

Error Occurs
    │
    ├─── Network Error
    │    └─→ Show "Connection issue" message
    │        └─→ Retry button available
    │
    ├─── AI API Error
    │    └─→ Return fallback intelligence
    │        └─→ Log error for monitoring
    │
    ├─── Parse Error
    │    └─→ Return minimal structure
    │        └─→ Alert development team
    │
    └─── Cache Error
         └─→ Skip cache, call AI directly
             └─→ Still return result to user
```

---

**Architecture Version**: 1.0.0  
**Last Updated**: December 2024

