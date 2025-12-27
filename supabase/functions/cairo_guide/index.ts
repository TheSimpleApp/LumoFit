// supabase/functions/cairo_guide/index.ts
// Secure Gemini proxy for Fitness Guide
// Updated to use Gemini 2.5 Flash (latest stable model)
// Now location-agnostic - works with any destination

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

interface RequestBody {
  question?: string;
  destination?: string;
  userLocation?: string;
  fitnessLevel?: string;
  dietaryPreferences?: string[];
}

function buildSystemPrompt(
  question: string,
  destination?: string,
  userLocation?: string,
  fitnessLevel?: string,
  dietaryPreferences?: string[]
): string {
  const destName = destination || 'your destination';
  let context = "User context: ";
  if (userLocation) context += `Currently in ${userLocation}. `;
  if (fitnessLevel) context += `Fitness level: ${fitnessLevel}. `;
  if (dietaryPreferences && dietaryPreferences.length > 0) {
    context += `Dietary preferences: ${dietaryPreferences.join(", ")}. `;
  }

  return `You are a fitness travel expert helping visitors find gyms, healthy restaurants, fitness events, and outdoor activities in ${destName}.

Your role:
- Provide practical, actionable recommendations with specific place names and neighborhoods when you know them
- Use your knowledge of fitness facilities, healthy restaurants, running routes, parks, and outdoor activities in ${destName}
- Include helpful details like opening hours, price ranges, what to bring when available
- Be encouraging and enthusiastic about staying fit while traveling
- Keep responses concise (2-3 paragraphs max, under 200 words)
- If you don't know specific places, suggest types of activities and general tips

${context}

User question: ${question}`;
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

  let body: RequestBody | undefined;
  try {
    body = await req.json();
  } catch (e) {
    return new Response(
      JSON.stringify({ error: "Invalid JSON body" }),
      { status: 400, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
    );
  }

  const question = body?.question?.trim();
  if (!question) {
    return new Response(
      JSON.stringify({ error: "Missing 'question' in request body" }),
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

  const prompt = buildSystemPrompt(
    question,
    body?.destination,
    body?.userLocation,
    body?.fitnessLevel,
    body?.dietaryPreferences
  );

  try {
    // Using Gemini 2.5 Flash (stable model)
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_KEY}`;
    const geminiRes = await fetch(geminiUrl, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        contents: [
          { parts: [{ text: prompt }] }
        ],
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
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
      return new Response(
        JSON.stringify({ error: "Gemini API error", status: geminiRes.status, details: data }),
        { status: 502, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
      );
    }

    let text = "";
    if (data?.candidates?.length > 0) {
      const candidate = data.candidates[0];
      const parts = candidate?.content?.parts;
      if (Array.isArray(parts) && parts.length > 0) {
        text = parts[0]?.text ?? "";
      }
    }

    if (!text) {
      text = "Sorry, I couldn't generate a response. Please try again.";
    }

    return new Response(
      JSON.stringify({ text }),
      { status: 200, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
    );
  } catch (err) {
    console.error("Server error:", err);
    return new Response(
      JSON.stringify({ error: "Server error", details: String(err) }),
      { status: 500, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
    );
  }
}

Deno.serve(handler);
