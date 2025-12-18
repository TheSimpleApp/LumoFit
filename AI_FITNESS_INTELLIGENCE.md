# AI Fitness Intelligence for Places

## Overview

The Place Details screen now features **AI-powered Fitness Intelligence** that analyzes community reviews and place data to extract actionable insights for fitness-minded travelers. This enhancement uses Gemini AI to provide smart, context-aware recommendations focused on health, fitness, and active lifestyle.

## Features

### 1. **Comprehensive Fitness Analysis**
- **Fitness Score (0-10)**: AI-generated score indicating how suitable the place is for fitness enthusiasts
- **Smart Summary**: 2-3 sentence AI summary highlighting key fitness/health aspects
- **Review Sentiment**: Aggregated sentiment analysis with aspect-level scores

### 2. **Type-Specific Intelligence**

#### For Gyms:
- Equipment inventory (extracted from reviews)
- Cleanliness ratings
- Amenities (showers, lockers, WiFi, etc.)
- Coaching quality assessment
- Beginner-friendliness indicator
- Class schedule information (if mentioned)

#### For Restaurants:
- Healthy menu options
- Dietary accommodations (vegan, gluten-free, etc.)
- Macro information (protein-rich, low-carb mentions)
- Portion size feedback
- Protein score (0-10)
- Popular healthy dishes
- Post-workout friendliness

#### For Trails:
- Difficulty level (Easy/Moderate/Hard)
- Terrain description
- Distance in kilometers
- Elevation gain
- Scenic highlights
- Best season to visit
- Dog-friendly indicator
- Bike accessibility
- Water availability

### 3. **Smart Timing Insights**
- **Best Times to Visit**: AI-analyzed optimal times (morning, afternoon, evening)
- **Crowd Patterns**: Insights on when the place is busy or quiet
- Specific time recommendations with context

### 4. **Actionable Intelligence**
- **Pros & Cons**: Fitness-focused advantages and drawbacks
- **Fitness Tips**: Actionable advice for making the most of the place
- **What to Bring**: Recommended items based on place type and reviews
- **Common Phrases**: Frequently mentioned fitness-related themes from reviews

### 5. **Quick Insights Chips**
Visual chips showing key highlights:
- Best time indicators
- Crowd level badges
- Beginner-friendly tags
- Post-workout recommendations
- Dog-friendly indicators

## Technical Architecture

### Frontend Components

#### Models (`lib/models/ai_models.dart`)
```dart
PlaceFitnessIntelligence // Main intelligence model
├── GymIntelligence      // Gym-specific insights
├── RestaurantIntelligence // Restaurant-specific insights
├── TrailIntelligence    // Trail-specific insights
└── ReviewSentiment      // Sentiment analysis
```

#### Widgets (`lib/widgets/place_fitness_intelligence_card.dart`)
- `PlaceFitnessIntelligenceCard`: Main intelligence display
- `QuickInsightsChips`: Quick visual highlights
- `SmartTimingWidget`: Best times to visit
- Type-specific sections for gyms, restaurants, trails

#### Service Integration (`lib/services/ai_guide_service.dart`)
```dart
Future<PlaceFitnessIntelligence?> analyzePlaceFitness({
  required String placeId,
  required String placeName,
  required String placeType,
  List<Map<String, dynamic>>? reviews,
  Map<String, dynamic>? placeData,
})
```

### Backend (Supabase Edge Function)

**Function**: `analyze_place_fitness`
- **Location**: `supabase/functions/analyze_place_fitness/`
- **AI Model**: Gemini 2.0 Flash Exp
- **Caching**: 24-hour TTL in `place_fitness_intelligence_cache` table

#### Caching Strategy
1. Check cache for recent analysis (< 24 hours old)
2. If cache hit, return immediately
3. If cache miss, call Gemini API
4. Store result in cache with metadata
5. Cleanup old entries (> 7 days) periodically

### Database Schema

```sql
CREATE TABLE place_fitness_intelligence_cache (
  id UUID PRIMARY KEY,
  place_id TEXT NOT NULL,
  place_name TEXT NOT NULL,
  place_type TEXT NOT NULL,
  intelligence JSONB NOT NULL,
  reviews_analyzed INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
- `idx_place_fitness_cache_place_id`: Fast lookups
- `idx_place_fitness_cache_created_at`: Cache expiration
- `idx_place_fitness_cache_lookup`: Composite for cache hits

## User Experience Flow

1. **User opens place details**
   - Loading indicator appears
   - AI analysis begins in background

2. **Analysis completes**
   - Fitness Intelligence card displays with gradient background
   - Fitness score badge shows overall rating
   - Summary provides quick overview

3. **User explores insights**
   - Type-specific sections reveal detailed information
   - Pros/cons help with decision-making
   - Tips provide actionable advice
   - Smart timing helps plan visits

4. **Quick insights at a glance**
   - Chips show key highlights
   - Best time recommendations
   - Crowd level indicators

## AI Prompt Engineering

The system uses carefully crafted prompts that:
- Focus on fitness, health, and active lifestyle
- Extract specific, actionable information
- Provide honest assessments
- Include type-specific fields
- Request structured JSON output

### Example Prompt Structure
```
You are a fitness and health travel expert analyzing [PLACE_NAME], a [TYPE] in Egypt.

COMMUNITY REVIEWS:
[REVIEW_TEXT]

PLACE DATA:
[STRUCTURED_DATA]

Analyze from FITNESS, HEALTH, and ACTIVE LIFESTYLE perspective.
Return JSON with specific structure...
```

## Performance Optimizations

1. **Caching**: 24-hour cache reduces API calls by ~95%
2. **Async Loading**: Non-blocking UI, intelligence loads in background
3. **Fallback Handling**: Graceful degradation if AI unavailable
4. **Efficient Queries**: Indexed database lookups
5. **Batch Processing**: Single AI call per place

## Cost Considerations

- **Gemini API**: ~$0.001 per analysis (2K tokens)
- **Caching**: Reduces costs by 95% for popular places
- **Cleanup**: Automatic removal of stale cache entries
- **Estimated**: $0.50/month for 500 unique places

## Future Enhancements

### Planned Features
1. **Personalized Intelligence**: Adapt insights based on user fitness level
2. **Comparative Analysis**: Compare multiple places side-by-side
3. **Trend Detection**: Track changes in place quality over time
4. **Photo Analysis**: Extract insights from community photos
5. **Real-time Updates**: Update intelligence as new reviews arrive

### Potential Improvements
1. **Multi-language Support**: Analyze reviews in multiple languages
2. **Voice Insights**: Audio summaries of key points
3. **AR Integration**: Overlay insights on camera view
4. **Social Proof**: Show which insights other users found helpful
5. **Booking Integration**: Direct booking for gyms/classes

## Testing

### Manual Testing Checklist
- [ ] Intelligence loads for gyms
- [ ] Intelligence loads for restaurants
- [ ] Intelligence loads for trails
- [ ] Loading state displays correctly
- [ ] Cache hit works (second visit)
- [ ] Fallback handles errors gracefully
- [ ] Type-specific sections show relevant data
- [ ] Quick insights chips display
- [ ] Smart timing widget works
- [ ] Tips section renders properly

### Test Places
1. **Gym**: Gold's Gym Maadi (should show equipment, amenities)
2. **Restaurant**: Zooba (should show healthy options, dietary info)
3. **Trail**: Wadi Degla (should show difficulty, terrain)

## Troubleshooting

### Intelligence Not Loading
1. Check Gemini API key is set in Supabase secrets
2. Verify edge function is deployed
3. Check network connectivity
4. Review edge function logs

### Incorrect Analysis
1. Verify review data quality
2. Check prompt engineering
3. Review AI model temperature settings
4. Ensure place type is correctly categorized

### Cache Issues
1. Check cache table exists
2. Verify RLS policies
3. Review cleanup function
4. Check timestamp indexes

## Deployment

### Prerequisites
1. Gemini API key configured in Supabase
2. Edge function deployed
3. Database migration applied
4. RLS policies enabled

### Deployment Steps
```bash
# 1. Apply database migration
supabase db push

# 2. Deploy edge function
supabase functions deploy analyze_place_fitness

# 3. Set secrets
supabase secrets set GEMINI_API_KEY=your_key_here

# 4. Test function
supabase functions invoke analyze_place_fitness \
  --data '{"placeId":"test","placeName":"Test Gym","placeType":"gym"}'
```

## Monitoring

### Key Metrics
- Cache hit rate (target: >90%)
- Average response time (target: <2s)
- AI analysis accuracy (user feedback)
- Cost per analysis
- Error rate

### Logs to Monitor
- Edge function invocations
- Cache misses
- AI API errors
- Parse failures
- Database errors

## Privacy & Data

### Data Collection
- Place IDs (anonymized)
- Review texts (user-generated, public)
- Analysis results (cached)
- No personal user data

### Data Retention
- Cache: 7 days
- Logs: 30 days
- Analytics: Aggregated only

### Compliance
- GDPR: No personal data processed
- User consent: Implicit (public reviews)
- Data deletion: Automatic cleanup

## Credits

- **AI Model**: Google Gemini 2.0 Flash Exp
- **Design**: Fitness-first approach
- **Architecture**: Serverless edge functions
- **Caching**: Supabase PostgreSQL

---

**Version**: 1.0.0  
**Last Updated**: December 2024  
**Maintainer**: FitTravel Team

