import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const AIML_API_KEY = Deno.env.get("AIML_API_KEY");
const AIML_BASE_URL = "https://api.aimlapi.com/v1";

interface RecommendationRequest {
  query: string;
  userProfile?: {
    fitnessLevel?: string;
    preferences?: string[];
    location?: { lat: number; lng: number };
  };
  availableEvents?: Array<{
    id: string;
    title: string;
    category: string;
    start: string;
    venue?: string;
    distance?: number;
  }>;
  model?: string;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body: RecommendationRequest = await req.json();
    const { query, userProfile, availableEvents, model = "gpt-4o-mini" } = body;

    if (!AIML_API_KEY) {
      return new Response(
        JSON.stringify({ error: "AIML API key not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const systemPrompt = `You are a fitness travel assistant for LumoFit, an app that helps fitness travelers discover gyms, healthy restaurants, running events, and local fitness communities worldwide.

Your role is to:
1. Help users find the best fitness events and activities based on their preferences and location
2. Provide personalized recommendations considering fitness level and interests
3. Be specific with venue names, dates, and practical details
4. If events are provided, rank them by relevance and explain why each is a good match

Keep responses concise but informative. Use a friendly, motivating tone.`;

    let userPrompt = `User query: ${query}`;

    if (userProfile) {
      userPrompt += `\n\nUser profile:`;
      if (userProfile.fitnessLevel) {
        userPrompt += `\n- Fitness level: ${userProfile.fitnessLevel}`;
      }
      if (userProfile.preferences?.length) {
        userPrompt += `\n- Preferences: ${userProfile.preferences.join(", ")}`;
      }
      if (userProfile.location) {
        userPrompt += `\n- Location: ${userProfile.location.lat.toFixed(4)}, ${userProfile.location.lng.toFixed(4)}`;
      }
    }

    if (availableEvents?.length) {
      userPrompt += `\n\nAvailable events nearby (${availableEvents.length} found):\n`;
      userPrompt += JSON.stringify(availableEvents.slice(0, 15), null, 2);
      userPrompt += `\n\nPlease recommend the most relevant events from this list and explain why they're a good fit.`;
    }

    const response = await fetch(`${AIML_BASE_URL}/chat/completions`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${AIML_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        temperature: 0.7,
        max_tokens: 1024,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("AIML API error:", errorText);
      return new Response(
        JSON.stringify({ error: "AIML API request failed", details: errorText }),
        { status: response.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const data = await response.json();
    const text = data.choices?.[0]?.message?.content || "No recommendations available.";

    return new Response(
      JSON.stringify({
        text,
        model,
        usage: data.usage,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in aiml_recommendations:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: String(error) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
