// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface AnalysisRequest {
  placeId: string
  placeName: string
  placeType: string
  reviews?: Array<{
    rating: number
    text?: string
    createdAt: string
  }>
  placeData?: {
    name: string
    type: string
    rating?: number
    userRatingsTotal?: number
    priceLevel?: string
    openingHours?: string[]
  }
}

serve(async (req) => {
  // CORS headers
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Parse request
    const body: AnalysisRequest = await req.json()
    const { placeId, placeName, placeType, reviews = [], placeData } = body

    // Check cache first (24 hour TTL)
    const { data: cached } = await supabase
      .from('place_fitness_intelligence_cache')
      .select('*')
      .eq('place_id', placeId)
      .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
      .single()

    if (cached) {
      console.log(`Cache hit for place ${placeId}`)
      return new Response(
        JSON.stringify({ intelligence: cached.intelligence }),
        {
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      )
    }

    // Build context for AI
    const reviewTexts = reviews
      .filter((r) => r.text && r.text.trim().length > 0)
      .map((r) => `[${r.rating}/5] ${r.text}`)
      .join('\n')

    const hasReviews = reviewTexts.length > 0

    // Build prompt based on place type
    const prompt = buildAnalysisPrompt(placeName, placeType, reviewTexts, placeData, hasReviews)

    // Call Gemini API
    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 2048,
          },
        }),
      }
    )

    if (!geminiResponse.ok) {
      throw new Error(`Gemini API error: ${geminiResponse.status}`)
    }

    const geminiData = await geminiResponse.json()
    const responseText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text

    if (!responseText) {
      throw new Error('No response from Gemini')
    }

    // Parse JSON response
    const intelligence = parseAiResponse(responseText, reviews.length)

    // Cache the result
    await supabase.from('place_fitness_intelligence_cache').upsert({
      place_id: placeId,
      place_name: placeName,
      place_type: placeType,
      intelligence,
      reviews_analyzed: reviews.length,
      created_at: new Date().toISOString(),
    })

    return new Response(
      JSON.stringify({ intelligence }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  } catch (error) {
    console.error('Error analyzing place fitness:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  }
})

function buildAnalysisPrompt(
  placeName: string,
  placeType: string,
  reviewTexts: string,
  placeData: any,
  hasReviews: boolean
): string {
  const basePrompt = `You are a fitness and health travel expert analyzing "${placeName}", a ${placeType} in Egypt.

${hasReviews ? `COMMUNITY REVIEWS:\n${reviewTexts}\n\n` : ''}

${placeData ? `PLACE DATA:\nRating: ${placeData.rating || 'N/A'}\nPrice: ${placeData.priceLevel || 'N/A'}\n\n` : ''}

Analyze this place from a FITNESS, HEALTH, and ACTIVE LIFESTYLE perspective. Extract actionable insights that help fitness-minded travelers.

Return a JSON object with this EXACT structure (no markdown, just raw JSON):

{
  "summary": "2-3 sentence fitness-focused summary",
  "fitnessScore": 7.5,
  "bestTimesDetailed": {
    "morning": "6-9 AM - Description",
    "evening": "After 7 PM - Description"
  },
  "crowdInsights": "Brief crowd pattern analysis",
  ${getTypeSpecificFields(placeType)}
  "pros": ["Fitness pro 1", "Fitness pro 2", "Fitness pro 3"],
  "cons": ["Fitness con 1", "Fitness con 2"],
  "tips": ["Actionable tip 1", "Actionable tip 2", "Actionable tip 3"],
  "whatToBring": ["Item 1", "Item 2", "Item 3"],
  "sentiment": {
    "overall": 0.7,
    "label": "Very Positive",
    "aspectScores": {"cleanliness": 0.8, "equipment": 0.9}
  },
  "commonPhrases": ["phrase1", "phrase2", "phrase3"],
  "generatedAt": "${new Date().toISOString()}",
  "reviewsAnalyzed": ${hasReviews ? 'ACTUAL_COUNT' : '0'}
}

Focus on:
- Fitness/health-specific details
- Crowd patterns and best times
- Equipment, amenities, or healthy options
- Practical tips for active travelers
- Extract sentiment and common themes

Be specific, actionable, and honest. If there's not enough data, be conservative with scores.`

  return basePrompt
}

function getTypeSpecificFields(placeType: string): string {
  switch (placeType.toLowerCase()) {
    case 'gym':
      return `"gymInsights": {
    "equipment": ["Equipment 1", "Equipment 2"],
    "cleanlinessRating": "Excellent/Good/Fair",
    "amenities": ["Showers", "Lockers", "WiFi"],
    "coachingQuality": "Brief assessment",
    "beginnerFriendly": true
  },`
    case 'restaurant':
      return `"restaurantInsights": {
    "healthyOptions": ["Option 1", "Option 2"],
    "dietaryAccommodations": ["Vegan", "Gluten-free"],
    "macroInfo": "Protein-rich options available",
    "portionSize": "Large/Medium/Small",
    "proteinScore": 8.0,
    "popularHealthyDishes": ["Dish 1", "Dish 2"],
    "postWorkoutFriendly": true
  },`
    case 'trail':
      return `"trailInsights": {
    "difficulty": "Easy/Moderate/Hard",
    "terrain": "Description",
    "distanceKm": 5.0,
    "elevationGain": "Description",
    "scenicHighlights": ["Highlight 1", "Highlight 2"],
    "bestSeason": "Season",
    "dogFriendly": true,
    "bikeAccessible": false,
    "waterAvailability": "Description"
  },`
    default:
      return ''
  }
}

function parseAiResponse(responseText: string, reviewCount: number): any {
  try {
    // Remove markdown code blocks if present
    let cleaned = responseText.trim()
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.replace(/^```json\n/, '').replace(/\n```$/, '')
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.replace(/^```\n/, '').replace(/\n```$/, '')
    }

    const parsed = JSON.parse(cleaned)
    
    // Ensure reviewsAnalyzed is set correctly
    parsed.reviewsAnalyzed = reviewCount

    return parsed
  } catch (error) {
    console.error('Failed to parse AI response:', error)
    console.error('Response text:', responseText)
    
    // Return a fallback structure
    return {
      summary: 'Unable to generate detailed insights at this time.',
      fitnessScore: null,
      bestTimesDetailed: {},
      crowdInsights: null,
      pros: [],
      cons: [],
      tips: [],
      whatToBring: [],
      sentiment: null,
      commonPhrases: [],
      generatedAt: new Date().toISOString(),
      reviewsAnalyzed: reviewCount,
    }
  }
}

