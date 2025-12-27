// supabase/functions/generate_fitness_itinerary/index.ts
// Generate fitness-focused day itineraries for any destination
// Location-agnostic - works with any city worldwide

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

interface ItineraryRequest {
  destination: string;
  date: string;
  fitnessLevel?: string;
  focusAreas?: string[];
}

interface ItineraryItem {
  time: string;
  duration: number;
  type: 'activity' | 'meal' | 'rest' | 'travel';
  title: string;
  description: string;
  tips?: string;
  placeName?: string;
}

interface ItineraryResponse {
  title: string;
  destination: string;
  items: ItineraryItem[];
  packingList: string[];
}

function buildPrompt(request: ItineraryRequest): string {
  const { destination, date, fitnessLevel = 'intermediate', focusAreas = [] } = request;
  const focusStr = focusAreas.length > 0 ? focusAreas.join(', ') : 'balanced fitness';

  return `Create a fitness day itinerary for ${destination} on ${date}.
Fitness level: ${fitnessLevel}. Focus: ${focusStr}.

Use your knowledge of ${destination} to suggest specific places, running routes, gyms, and healthy restaurants when you know them.
If you don't know specific places, suggest general types of activities that work well in that location.

Return ONLY valid JSON (no markdown):
{
  "title": "catchy title",
  "destination": "${destination}",
  "items": [
    {"time": "HH:MM", "duration": minutes, "type": "activity|meal|rest|travel", "title": "short title", "description": "2-3 sentences", "tips": "optional tip", "placeName": "optional place"}
  ],
  "packingList": ["item1", "item2"]
}

Create 6-8 items from 5-6am to 8-9pm. Balance activities with meals and rest. Be specific to ${destination} when possible.`;
}

function parseItineraryResponse(responseText: string, destination: string): ItineraryResponse {
  try {
    let cleaned = responseText.trim();

    const jsonMatch = cleaned.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (jsonMatch) {
      cleaned = jsonMatch[1].trim();
    }

    const firstBrace = cleaned.indexOf('{');
    const lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace !== -1 && lastBrace > firstBrace) {
      cleaned = cleaned.slice(firstBrace, lastBrace + 1);
    }

    const itinerary = JSON.parse(cleaned) as ItineraryResponse;

    return {
      title: itinerary.title || `Active Day in ${destination}`,
      destination: destination,
      items: itinerary.items || [],
      packingList: itinerary.packingList || ['Water bottle', 'Sunscreen', 'Comfortable shoes'],
    };
  } catch {
    // Return default itinerary
    return {
      title: `Active Day in ${destination}`,
      destination: destination,
      items: [
        { time: '06:00', duration: 60, type: 'activity', title: 'Morning Workout', description: `Start with exercise in ${destination}. Check hotel fitness facilities or nearby running routes.` },
        { time: '07:30', duration: 45, type: 'meal', title: 'Healthy Breakfast', description: 'Fuel up with a protein-rich breakfast. Look for local healthy options.' },
        { time: '09:00', duration: 180, type: 'activity', title: 'Explore & Stay Active', description: `Explore ${destination}'s attractions while staying active. Walking tours burn calories.` },
        { time: '13:00', duration: 60, type: 'meal', title: 'Light Lunch', description: 'Grilled proteins and fresh salads are great options.' },
        { time: '14:30', duration: 90, type: 'rest', title: 'Midday Rest', description: 'Rest, hydrate, and prepare for evening activities.' },
        { time: '17:00', duration: 90, type: 'activity', title: 'Evening Activity', description: 'Get another workout or active sightseeing as temperatures cool.' },
        { time: '19:30', duration: 60, type: 'meal', title: 'Dinner', description: 'Look for grilled and vegetable-focused options.' },
      ],
      packingList: ['Water bottle', 'Sunscreen', 'Hat', 'Comfortable walking shoes', 'Light workout clothes'],
    };
  }
}

async function handler(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
    );
  }

  let body: ItineraryRequest | undefined;
  try {
    body = await req.json();
  } catch (e) {
    return new Response(
      JSON.stringify({ error: "Invalid JSON body" }),
      { status: 400, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
    );
  }

  if (!body?.destination || !body?.date) {
    return new Response(
      JSON.stringify({ error: "destination and date are required" }),
      { status: 400, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
    );
  }

  const GEMINI_KEY = Deno.env.get("GEMENI_API_KEY") || Deno.env.get("GEMINI_API_KEY");
  if (!GEMINI_KEY) {
    return new Response(
      JSON.stringify({ error: "Server misconfigured: Gemini API key not set" }),
      { status: 500, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
    );
  }

  const prompt = buildPrompt(body);

  try {
    const geminiUrl = `https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=${GEMINI_KEY}`;
    const geminiRes = await fetch(geminiUrl, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.8,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1500,
        },
        safetySettings: [
          { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
          { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
          { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
          { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" }
        ]
      })
    });

    const data = await geminiRes.json();

    if (!geminiRes.ok) {
      console.error("Gemini API error:", data);
      // Return default itinerary on API error
      const defaultItinerary = parseItineraryResponse("", body.destination);
      return new Response(
        JSON.stringify(defaultItinerary),
        { status: 200, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
      );
    }

    let rawText = "";
    if (data?.candidates?.length > 0) {
      const candidate = data.candidates[0];
      const parts = candidate?.content?.parts;
      if (Array.isArray(parts) && parts.length > 0) {
        rawText = parts[0]?.text ?? "";
      }
    }

    const itinerary = parseItineraryResponse(rawText, body.destination);

    return new Response(
      JSON.stringify(itinerary),
      { status: 200, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
    );
  } catch (err) {
    console.error("Server error:", err);
    // Return default itinerary on server error
    const defaultItinerary = parseItineraryResponse("", body.destination);
    return new Response(
      JSON.stringify(defaultItinerary),
      { status: 200, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
    );
  }
}

Deno.serve(handler);
