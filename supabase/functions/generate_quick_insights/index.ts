// Edge Function: Generate Quick Insights for Places
// Uses Gemini 2.5 Flash for fast, lightweight insights generation
// Caches results for 7 days to optimize performance and reduce API costs

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestBody {
  placeName: string
  placeType: string
  rating?: number
  reviewCount?: number
  googlePlaceId?: string
  model?: string
}

interface QuickInsights {
  tags: string[]
  vibe?: string
  bestFor?: string
  quickTip?: string
  generatedAt: string
  fromCache: boolean
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse request body
    const body: RequestBody = await req.json()
    const { placeName, placeType, rating, reviewCount, googlePlaceId, model = 'gemini-2.0-flash-exp' } = body

    if (!placeName || !placeType) {
      return new Response(
        JSON.stringify({ error: 'placeName and placeType are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Check cache first (7 day cache)
    const cacheKey = `quick_insights_${googlePlaceId || placeName.toLowerCase().replace(/\s+/g, '_')}`
    const { data: cachedData } = await supabase
      .from('ai_insights_cache')
      .select('insights, created_at')
      .eq('cache_key', cacheKey)
      .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
      .single()

    if (cachedData?.insights) {
      console.log('Returning cached quick insights for:', placeName)
      return new Response(
        JSON.stringify({
          insights: {
            ...cachedData.insights,
            fromCache: true,
          },
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate new insights using Gemini Flash
    const geminiApiKey = Deno.env.get('GOOGLE_GEMINI_API_KEY')
    if (!geminiApiKey) {
      throw new Error('GOOGLE_GEMINI_API_KEY not configured')
    }

    // Build prompt for quick insights
    const prompt = `You are analyzing a ${placeType} called "${placeName}" for a fitness travel app.

Place Details:
- Type: ${placeType}
- Rating: ${rating ? rating.toFixed(1) : 'N/A'}/5
- Review Count: ${reviewCount || 'N/A'}

Generate quick, actionable insights to help fitness travelers decide if this place is right for them.

Provide your response in JSON format with these fields:
{
  "tags": ["tag1", "tag2", "tag3", "tag4"],  // 3-6 short tags (e.g., "Great Equipment", "Crowded Evenings", "Protein-Rich Menu")
  "vibe": "2-3 word description",  // Overall vibe (e.g., "Energetic & Social", "Quiet & Focused")
  "bestFor": "target audience",  // Who it's best for (e.g., "Serious Lifters", "Yoga Enthusiasts", "Health-Conscious Travelers")
  "quickTip": "one actionable tip"  // One quick tip (e.g., "Come early for machines", "Try the grilled chicken salad")
}

Keep all text concise and actionable. Tags should be 2-4 words max.`

    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiApiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 500,
            responseMimeType: 'application/json',
          },
        }),
      }
    )

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text()
      console.error('Gemini API error:', errorText)
      throw new Error(`Gemini API error: ${geminiResponse.status}`)
    }

    const geminiData = await geminiResponse.json()
    const responseText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text

    if (!responseText) {
      throw new Error('No response from Gemini')
    }

    // Parse JSON response
    let insights: QuickInsights
    try {
      const parsed = JSON.parse(responseText)
      insights = {
        tags: parsed.tags || [],
        vibe: parsed.vibe,
        bestFor: parsed.bestFor,
        quickTip: parsed.quickTip,
        generatedAt: new Date().toISOString(),
        fromCache: false,
      }
    } catch (parseError) {
      console.error('Failed to parse Gemini response:', responseText)
      // Provide fallback insights
      insights = {
        tags: [`${rating && rating >= 4 ? 'Highly Rated' : 'Popular Spot'}`],
        generatedAt: new Date().toISOString(),
        fromCache: false,
      }
    }

    // Cache the results
    await supabase.from('ai_insights_cache').upsert({
      cache_key: cacheKey,
      insights: insights,
      created_at: new Date().toISOString(),
    })

    console.log('Generated new quick insights for:', placeName)

    return new Response(
      JSON.stringify({ insights }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error generating quick insights:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Failed to generate quick insights',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

