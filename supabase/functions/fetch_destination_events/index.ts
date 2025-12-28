// supabase/functions/fetch_destination_events/index.ts
// Fetches and stores fitness events for a destination using AI research
// Uses AIML API with Perplexity sonar-pro model for real-time web search
// Triggered by trip creation/updates or can be called directly

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

const AIML_BASE_URL = "https://api.aimlapi.com/v1";

interface RequestBody {
  city: string;
  country?: string;
  start_date?: string; // ISO date
  end_date?: string; // ISO date
  latitude?: number;
  longitude?: number;
  max_events?: number;
  trip_id?: string; // For linking to specific trip
}

interface FitnessEvent {
  title: string;
  category: string;
  start_date: string;
  end_date?: string;
  description?: string;
  venue_name: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  website_url?: string;
  registration_url?: string;
  price_info?: string;
  source?: string;
  external_id?: string;
  image_url?: string;
}

const EVENT_CATEGORIES = [
  'running', 'yoga', 'hiking', 'cycling', 'crossfit', 'swimming',
  'bootcamp', 'triathlon', 'obstacle', 'group_fitness',
  'martial_arts', 'dance', 'climbing', 'wellness', 'sports', 'other'
];

function mapToCategory(cat: string): string {
  const lower = cat.toLowerCase();
  if (lower.includes('run') || lower.includes('5k') || lower.includes('10k') || lower.includes('marathon')) return 'running';
  if (lower.includes('yoga') || lower.includes('pilates')) return 'yoga';
  if (lower.includes('hik') || lower.includes('trek')) return 'hiking';
  if (lower.includes('cycl') || lower.includes('bike') || lower.includes('spin')) return 'cycling';
  if (lower.includes('crossfit') || lower.includes('functional')) return 'crossfit';
  if (lower.includes('swim')) return 'swimming';
  if (lower.includes('boot') || lower.includes('hiit')) return 'bootcamp';
  if (lower.includes('triath') || lower.includes('duath')) return 'triathlon';
  if (lower.includes('obstacle') || lower.includes('spartan') || lower.includes('tough mudder')) return 'obstacle';
  if (lower.includes('class') || lower.includes('fitness')) return 'group_fitness';
  if (lower.includes('martial') || lower.includes('boxing') || lower.includes('mma') || lower.includes('karate')) return 'martial_arts';
  if (lower.includes('dance') || lower.includes('zumba')) return 'dance';
  if (lower.includes('climb') || lower.includes('boulder')) return 'climbing';
  if (lower.includes('well') || lower.includes('spa') || lower.includes('meditat')) return 'wellness';
  if (lower.includes('sport') || lower.includes('tournament') || lower.includes('match')) return 'sports';
  return 'other';
}

async function fetchEventsWithAIML(
  city: string,
  country: string | undefined,
  startDate: string,
  endDate: string,
  apiKey: string
): Promise<FitnessEvent[]> {
  const location = country ? `${city}, ${country}` : city;
  const prompt = `Find real, upcoming fitness and wellness events in ${location} between ${startDate} and ${endDate}.

Search for:
- Running events (5K, 10K, marathons, fun runs, trail runs)
- Yoga classes, workshops, and retreats
- Hiking and outdoor adventure groups
- Cycling events and group rides
- CrossFit competitions and community events
- Swimming meets and aquatic fitness
- Bootcamp and HIIT sessions
- Triathlons and multi-sport events
- Obstacle course races
- Dance fitness classes (Zumba, etc.)
- Martial arts tournaments
- Climbing events
- Wellness festivals and health expos
- Group fitness meetups

For each event found, provide:
1. Event title
2. Category (running, yoga, hiking, cycling, crossfit, swimming, bootcamp, triathlon, obstacle, group_fitness, martial_arts, dance, climbing, wellness, sports, other)
3. Start date and time (ISO format: YYYY-MM-DDTHH:MM:SS)
4. End date/time if applicable
5. Venue name
6. Full address
7. Brief description
8. Registration/website URL
9. Price info (if available)
10. Event source (where you found it)

Return as JSON array of events. Focus on verified, real events from official sources like:
- Local running clubs
- Eventbrite
- RunSignUp
- Facebook events
- MeetUp groups
- Local gym websites
- City recreation departments

Include recurring fitness classes/meetups if they're popular in the area.

IMPORTANT: Return ONLY a valid JSON array, no other text or markdown formatting.

Format:
[
  {
    "title": "Event Name",
    "category": "running",
    "start_date": "2025-01-15T08:00:00",
    "end_date": "2025-01-15T12:00:00",
    "venue_name": "Location Name",
    "address": "Full address",
    "description": "Brief description",
    "website_url": "https://...",
    "registration_url": "https://...",
    "price_info": "Free" or "$25",
    "source": "eventbrite" or "local running club" etc.
  }
]`;

  try {
    console.log(`Calling AIML API with perplexity/sonar-pro for ${location}...`);

    const res = await fetch(`${AIML_BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'perplexity/sonar-pro',
        messages: [
          {
            role: 'system',
            content: 'You are a fitness event researcher with real-time web search capabilities. Return ONLY valid JSON arrays with no markdown formatting, code blocks, or explanations. Your responses should be parseable JSON.'
          },
          { role: 'user', content: prompt }
        ],
        temperature: 0.3,
        max_tokens: 4000,
      }),
    });

    if (!res.ok) {
      const errorText = await res.text();
      console.error('AIML API error:', res.status, errorText);
      return [];
    }

    const data = await res.json();
    const content = data.choices?.[0]?.message?.content || '';

    console.log('AIML response length:', content.length);

    // Clean the response - remove markdown code blocks if present
    let cleanContent = content.trim();
    const codeFenceMatch = cleanContent.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
    if (codeFenceMatch) {
      cleanContent = codeFenceMatch[1].trim();
    }

    // Extract JSON array from response
    const jsonMatch = cleanContent.match(/\[\s*\{[\s\S]*\}\s*\]/);
    if (!jsonMatch) {
      console.log('No JSON array found in AIML response:', cleanContent.substring(0, 500));
      return [];
    }

    const events = JSON.parse(jsonMatch[0]);
    console.log(`Parsed ${events.length} events from AIML response`);

    return events.map((e: any) => ({
      title: e.title || 'Untitled Event',
      category: mapToCategory(e.category || 'other'),
      start_date: e.start_date,
      end_date: e.end_date,
      description: e.description,
      venue_name: e.venue_name || 'TBA',
      address: e.address,
      latitude: e.latitude,
      longitude: e.longitude,
      website_url: e.website_url,
      registration_url: e.registration_url,
      price_info: e.price_info,
      source: e.source || 'perplexity_sonar',
      external_id: e.external_id || `aiml_${city.replace(/\s+/g, '_')}_${(e.title || '').replace(/\s+/g, '_').substring(0, 30)}_${Date.now()}`,
    }));
  } catch (err) {
    console.error('AIML fetch error:', err);
    return [];
  }
}

async function fetchEventsWithGemini(
  city: string,
  country: string | undefined,
  startDate: string,
  endDate: string,
  apiKey: string
): Promise<FitnessEvent[]> {
  const location = country ? `${city}, ${country}` : city;
  const prompt = `You are a fitness event database. Generate realistic fitness events that would typically occur in ${location} between ${startDate} and ${endDate}.

Based on your knowledge of ${location}:
- Include local gyms, fitness centers, and their regular classes
- Running clubs and their typical weekly/monthly runs
- Yoga studios and their popular sessions
- Parks suitable for outdoor fitness activities
- Any major fitness events or races you know about

Return 10-15 realistic events as JSON:
[
  {
    "title": "Event Name",
    "category": "running|yoga|hiking|cycling|crossfit|swimming|bootcamp|group_fitness|martial_arts|dance|climbing|wellness|sports|other",
    "start_date": "2025-01-15T08:00:00",
    "end_date": "2025-01-15T10:00:00",
    "venue_name": "Real Venue Name in ${city}",
    "address": "Realistic address in ${city}",
    "description": "Brief description",
    "website_url": "https://realistic-url.com",
    "price_info": "Free|$X"
  }
]

Use real venue names and addresses you know exist in ${city}. Return ONLY valid JSON.`;

  try {
    console.log(`Falling back to Gemini for ${location}...`);

    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 4000,
          },
        }),
      }
    );

    if (!res.ok) {
      console.error('Gemini API error:', await res.text());
      return [];
    }

    const data = await res.json();
    const content = data.candidates?.[0]?.content?.parts?.[0]?.text || '';

    // Clean and extract JSON
    let cleanContent = content.replace(/```json\s*/g, '').replace(/```\s*/g, '').trim();
    const jsonMatch = cleanContent.match(/\[\s*\{[\s\S]*\}\s*\]/);
    if (!jsonMatch) {
      console.log('No JSON in Gemini response');
      return [];
    }

    const events = JSON.parse(jsonMatch[0]);
    console.log(`Parsed ${events.length} events from Gemini`);

    return events.map((e: any, idx: number) => ({
      title: e.title || 'Untitled Event',
      category: mapToCategory(e.category || 'other'),
      start_date: e.start_date,
      end_date: e.end_date,
      description: e.description,
      venue_name: e.venue_name || 'TBA',
      address: e.address,
      latitude: e.latitude,
      longitude: e.longitude,
      website_url: e.website_url,
      registration_url: e.registration_url,
      price_info: e.price_info,
      source: 'ai_generated',
      external_id: `gem_${city.replace(/\s+/g, '_')}_${idx}_${Date.now()}`,
    }));
  } catch (err) {
    console.error('Gemini fetch error:', err);
    return [];
  }
}

async function handler(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: { ...CORS_HEADERS, 'content-type': 'application/json' } }
    );
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch (e) {
    return new Response(
      JSON.stringify({ error: 'Invalid JSON' }),
      { status: 400, headers: { ...CORS_HEADERS, 'content-type': 'application/json' } }
    );
  }

  if (!body.city) {
    return new Response(
      JSON.stringify({ error: 'Missing city parameter' }),
      { status: 400, headers: { ...CORS_HEADERS, 'content-type': 'application/json' } }
    );
  }

  // Get API keys - prioritize AIML for Perplexity access
  const AIML_KEY = Deno.env.get('AIML_API_KEY');
  const GEMINI_KEY = Deno.env.get('GEMENI_API_KEY') || Deno.env.get('GEMINI_API_KEY');
  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  if (!GEMINI_KEY && !AIML_KEY) {
    return new Response(
      JSON.stringify({ error: 'No AI API keys configured' }),
      { status: 500, headers: { ...CORS_HEADERS, 'content-type': 'application/json' } }
    );
  }

  const city = body.city;
  const country = body.country;
  const maxEvents = body.max_events || 50;

  // Default date range: next 3 months if not specified
  const now = new Date();
  const startDate = body.start_date || now.toISOString().split('T')[0];
  const defaultEnd = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000);
  const endDate = body.end_date || defaultEnd.toISOString().split('T')[0];

  console.log(`Fetching events for ${city}, ${country || 'N/A'} from ${startDate} to ${endDate}`);

  // Check if we already have recent events for this city
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  const { data: existingEvents } = await supabase
    .from('events')
    .select('id, fetched_at')
    .ilike('city', city)
    .gte('start_date', startDate)
    .order('fetched_at', { ascending: false })
    .limit(1);

  // If we have events fetched in the last 24 hours, skip re-fetching
  const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  if (existingEvents && existingEvents.length > 0 && existingEvents[0].fetched_at > oneDayAgo) {
    console.log('Events fetched recently, returning cached count');

    const { count } = await supabase
      .from('events')
      .select('*', { count: 'exact', head: true })
      .ilike('city', city)
      .gte('start_date', startDate)
      .lte('start_date', endDate);

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Using cached events',
        events_count: count || 0,
        cached: true
      }),
      { status: 200, headers: { ...CORS_HEADERS, 'content-type': 'application/json' } }
    );
  }

  // Fetch events from AI sources
  let allEvents: FitnessEvent[] = [];

  // Try AIML API first (provides Perplexity with real-time web search)
  if (AIML_KEY) {
    console.log('Fetching with AIML API (perplexity/sonar-pro)...');
    const aimlEvents = await fetchEventsWithAIML(city, country, startDate, endDate, AIML_KEY);
    allEvents.push(...aimlEvents);
    console.log(`AIML returned ${aimlEvents.length} events`);
  }

  // Fall back or supplement with Gemini if needed
  if (allEvents.length < 5 && GEMINI_KEY) {
    console.log('Supplementing with Gemini...');
    const geminiEvents = await fetchEventsWithGemini(city, country, startDate, endDate, GEMINI_KEY);
    allEvents.push(...geminiEvents);
    console.log(`Gemini returned ${geminiEvents.length} events`);
  }

  // Limit to max_events
  allEvents = allEvents.slice(0, maxEvents);

  if (allEvents.length === 0) {
    return new Response(
      JSON.stringify({
        success: true,
        message: 'No events found',
        events_count: 0
      }),
      { status: 200, headers: { ...CORS_HEADERS, 'content-type': 'application/json' } }
    );
  }

  // Insert events into Supabase
  const eventsToInsert = allEvents
    .filter(e => e.title && e.start_date)
    .map(e => ({
      title: e.title,
      category: e.category,
      start_date: e.start_date,
      end_date: e.end_date,
      description: e.description,
      venue_name: e.venue_name,
      address: e.address,
      latitude: e.latitude,
      longitude: e.longitude,
      website_url: e.website_url,
      registration_url: e.registration_url,
      external_id: e.external_id,
      image_url: e.image_url,
      price_info: e.price_info,
      source: e.source,
      city: city,
      country: country,
      fetched_at: new Date().toISOString(),
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7 days
    }));

  console.log(`Inserting ${eventsToInsert.length} events...`);

  // Upsert to handle duplicates (based on external_id)
  const { error: insertError } = await supabase
    .from('events')
    .upsert(eventsToInsert, {
      onConflict: 'external_id',
      ignoreDuplicates: true
    });

  if (insertError) {
    console.error('Insert error:', insertError);
    // Continue anyway, some events may have been inserted
  }

  // Get final count
  const { count: totalCount } = await supabase
    .from('events')
    .select('*', { count: 'exact', head: true })
    .ilike('city', city)
    .gte('start_date', startDate)
    .lte('start_date', endDate);

  return new Response(
    JSON.stringify({
      success: true,
      message: `Fetched ${eventsToInsert.length} events for ${city}`,
      events_count: totalCount || eventsToInsert.length,
      cached: false,
      source: AIML_KEY ? 'aiml_perplexity' : 'gemini'
    }),
    { status: 200, headers: { ...CORS_HEADERS, 'content-type': 'application/json' } }
  );
}

Deno.serve(handler);
