# AI Fitness Intelligence - Quick Start Guide

## For Developers

### Setup (5 minutes)

#### 1. Apply Database Migration
```bash
cd /Users/daviddotson/FitTravel-flutter-2
supabase db push
```

#### 2. Deploy Edge Function
```bash
supabase functions deploy analyze_place_fitness
```

#### 3. Set Gemini API Key
```bash
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here
```

#### 4. Test the Function
```bash
supabase functions invoke analyze_place_fitness \
  --data '{
    "placeId": "test-123",
    "placeName": "Test Gym",
    "placeType": "gym",
    "reviews": [
      {"rating": 5, "text": "Great equipment and clean facilities!"},
      {"rating": 4, "text": "Good gym but can get crowded in evenings"}
    ],
    "placeData": {
      "name": "Test Gym",
      "type": "gym",
      "rating": 4.5
    }
  }'
```

### Usage in Code

#### Basic Usage
```dart
// In your widget
final aiService = context.read<AiGuideService>();

final intelligence = await aiService.analyzePlaceFitness(
  placeId: place.id,
  placeName: place.name,
  placeType: place.type.name,
  reviews: reviewsJson,
  placeData: placeDataMap,
);

if (intelligence != null) {
  // Display intelligence
  PlaceFitnessIntelligenceCard(
    intelligence: intelligence,
    placeType: place.type.name,
  )
}
```

#### With Error Handling
```dart
try {
  setState(() => _isLoadingIntel = true);
  
  final intelligence = await aiService.analyzePlaceFitness(
    placeId: place.id,
    placeName: place.name,
    placeType: place.type.name,
    reviews: reviewsJson,
    placeData: placeDataMap,
  );
  
  if (mounted) {
    setState(() {
      _fitnessIntel = intelligence;
      _isLoadingIntel = false;
    });
  }
} catch (e) {
  debugPrint('Failed to load intelligence: $e');
  if (mounted) {
    setState(() => _isLoadingIntel = false);
  }
}
```

### Widget Components

#### 1. Main Intelligence Card
```dart
PlaceFitnessIntelligenceCard(
  intelligence: intelligence,
  placeType: 'gym', // or 'restaurant', 'trail'
)
```

#### 2. Quick Insights Chips
```dart
QuickInsightsChips(
  intelligence: intelligence,
)
```

#### 3. Smart Timing Widget
```dart
SmartTimingWidget(
  bestTimes: intelligence.bestTimesDetailed,
  crowdInsights: intelligence.crowdInsights,
)
```

### Testing

#### Manual Test Flow
1. Run the app: `flutter run`
2. Navigate to Discover tab
3. Search for a place (e.g., "Gold's Gym")
4. Tap on a place to open details
5. Wait for AI intelligence to load
6. Verify all sections display correctly
7. Go back and reopen (test cache)

#### Test Places
- **Gym**: "Gold's Gym Maadi"
- **Restaurant**: "Zooba"
- **Trail**: "Wadi Degla Protectorate"

### Debugging

#### Check Edge Function Logs
```bash
supabase functions logs analyze_place_fitness
```

#### Check Database Cache
```sql
SELECT 
  place_name,
  place_type,
  reviews_analyzed,
  created_at
FROM place_fitness_intelligence_cache
ORDER BY created_at DESC
LIMIT 10;
```

#### Clear Cache for Testing
```sql
DELETE FROM place_fitness_intelligence_cache
WHERE place_id = 'your-place-id';
```

### Common Issues

#### Issue: Intelligence not loading
**Solution**: Check edge function logs, verify Gemini API key

#### Issue: Cache not working
**Solution**: Verify RLS policies, check database connection

#### Issue: Incorrect analysis
**Solution**: Review prompt engineering, check review data quality

### Performance Tips

1. **Preload intelligence**: Call `analyzePlaceFitness()` early in screen lifecycle
2. **Show loading state**: Always display loading indicator
3. **Handle errors gracefully**: Provide fallback UI
4. **Monitor cache hit rate**: Aim for >90%

### Cost Optimization

1. **Use caching**: 24-hour TTL reduces costs by 95%
2. **Batch requests**: Don't call for every place view
3. **Monitor usage**: Track API calls in Supabase dashboard
4. **Set limits**: Implement rate limiting if needed

### Customization

#### Adjust Cache TTL
Edit edge function:
```typescript
// Change from 24 hours to 12 hours
.gte('created_at', new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString())
```

#### Modify AI Temperature
Edit edge function:
```typescript
generationConfig: {
  temperature: 0.5, // Lower = more consistent, Higher = more creative
  topK: 40,
  topP: 0.95,
}
```

#### Add Custom Fields
1. Update `PlaceFitnessIntelligence` model
2. Update edge function prompt
3. Update UI widgets

### Monitoring

#### Key Metrics to Track
```sql
-- Cache hit rate
SELECT 
  COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours') as cache_hits,
  COUNT(*) as total_requests,
  (COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours')::float / COUNT(*)) * 100 as hit_rate_percent
FROM place_fitness_intelligence_cache;

-- Popular places
SELECT 
  place_name,
  COUNT(*) as request_count,
  MAX(created_at) as last_analyzed
FROM place_fitness_intelligence_cache
GROUP BY place_name
ORDER BY request_count DESC
LIMIT 10;

-- Average reviews analyzed
SELECT 
  AVG(reviews_analyzed) as avg_reviews,
  place_type
FROM place_fitness_intelligence_cache
GROUP BY place_type;
```

### API Reference

#### AiGuideService.analyzePlaceFitness()

**Parameters**:
- `placeId` (String, required): Unique place identifier
- `placeName` (String, required): Display name of place
- `placeType` (String, required): Type: 'gym', 'restaurant', or 'trail'
- `reviews` (List<Map>, optional): Community reviews
- `placeData` (Map, optional): Additional place information

**Returns**: `Future<PlaceFitnessIntelligence?>`

**Example**:
```dart
final intel = await aiService.analyzePlaceFitness(
  placeId: 'abc-123',
  placeName: 'Gold\'s Gym',
  placeType: 'gym',
  reviews: [
    {'rating': 5, 'text': 'Great equipment!'},
  ],
  placeData: {'rating': 4.5},
);
```

### Model Structure

```dart
PlaceFitnessIntelligence(
  summary: String,                    // AI-generated summary
  fitnessScore: double?,              // 0-10 score
  bestTimesDetailed: Map<String, String>,
  crowdInsights: String?,
  gymInsights: GymIntelligence?,      // For gyms only
  restaurantInsights: RestaurantIntelligence?, // For restaurants only
  trailInsights: TrailIntelligence?,  // For trails only
  pros: List<String>,
  cons: List<String>,
  tips: List<String>,
  whatToBring: List<String>,
  sentiment: ReviewSentiment?,
  commonPhrases: List<String>,
  generatedAt: DateTime,
  reviewsAnalyzed: int,
)
```

### Next Steps

1. ✅ Deploy edge function
2. ✅ Test with sample data
3. ✅ Integrate into place details screen
4. ⏳ Monitor performance
5. ⏳ Gather user feedback
6. ⏳ Iterate on prompts

### Resources

- **Documentation**: `AI_FITNESS_INTELLIGENCE.md`
- **Architecture**: `AI_FITNESS_ARCHITECTURE.md`
- **Summary**: `PLACE_DETAILS_REFACTOR_SUMMARY.md`
- **Edge Function**: `supabase/functions/analyze_place_fitness/`
- **Models**: `lib/models/ai_models.dart`
- **Service**: `lib/services/ai_guide_service.dart`
- **Widgets**: `lib/widgets/place_fitness_intelligence_card.dart`

### Support

**Issues?** Check:
1. Edge function logs
2. Database cache table
3. API key configuration
4. Network connectivity

**Questions?** Review the full documentation in `AI_FITNESS_INTELLIGENCE.md`

---

**Quick Start Version**: 1.0.0  
**Last Updated**: December 2024

