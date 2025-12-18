// supabase/functions/egypt_fitness_guide/index.ts
// Enhanced Cairo fitness guide with dynamic, conversational responses
// Supports interactive elements: quick replies, selects, images, and places

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

interface ConversationMessage {
  role: string;
  content: string;
}

interface RequestBody {
  question?: string;
  destination?: string;
  userLocation?: { lat: number; lng: number };
  mapBounds?: Record<string, number>;
  fitnessLevel?: string;
  dietaryPreferences?: string[];
  conversationHistory?: ConversationMessage[];
  isGuidedSearch?: boolean;
}

interface QuickReply {
  id: string;
  text: string;
  emoji?: string;
  value?: string;
}

interface SelectChoice {
  id: string;
  text: string;
  emoji?: string;
  description?: string;
}

interface SelectOption {
  id: string;
  question: string;
  choices: SelectChoice[];
}

interface SuggestedPlace {
  name: string;
  type: string;
  neighborhood?: string;
  lat?: number;
  lng?: number;
  googlePlaceId?: string;
}

interface MessageElement {
  type: 'text' | 'quickReplies' | 'singleSelect' | 'multiSelect' | 'image' | 'places';
  text?: string;
  imageUrl?: string;
  quickReplies?: QuickReply[];
  selectOption?: SelectOption;
  places?: SuggestedPlace[];
}

interface EgyptGuideResponse {
  text: string;
  suggestedPlaces?: SuggestedPlace[];
  tags?: string[];
  elements?: MessageElement[];
  quickReplies?: QuickReply[];
}

function buildSystemPrompt(
  destination: string,
  conversationHistory: ConversationMessage[]
): string {
  const hasHistory = conversationHistory.length > 0;
  const isFirstMessage = conversationHistory.length <= 1;

  return `You are an enthusiastic Cairo fitness guide helping travelers stay active and eat healthy. You're conversational, fun, and always provide SHORT, dynamic responses.

CRITICAL RULES:
1. **Keep responses VERY SHORT** - 2-3 sentences maximum (under 60 words).
2. **Use "Tags" (Keywords)** - Extract 3-5 key concepts (e.g., "Best Gyms", "Healthy Food", "Zamalek", "Outdoor Run") as tags.
3. **Be conversational** - Ask follow-up questions to keep the chat going.
4. **Provide quick reply options** - Suggested follow-up queries.
5. **Give specific place names** with neighborhoods.

RESPONSE FORMAT:
You must return a valid JSON object with this structure:
{
  "text": "Your short, conversational response here (2-3 sentences)",
  "tags": ["Tag 1", "Tag 2", "Tag 3"],
  "quickReplies": [
    {"id": "1", "text": "Option 1", "emoji": "💪", "value": "Full question text"},
    {"id": "2", "text": "Option 2", "emoji": "🥗"}
  ],
  "suggestedPlaces": [
    {"name": "Place Name", "type": "gym|restaurant|park|trail", "neighborhood": "Zamalek"}
  ]
}

CONVERSATION STYLE:
- First message: Welcome warmly, ask what they're looking for.
- Follow-ups: Be specific, offer 2-3 quick reply options.
- Always: Keep it SHORT and scan-able.

CAIRO NEIGHBORHOODS:
- Zamalek (upscale, Nile-side, expats)
- Maadi (residential, family-friendly)
- Heliopolis (near airport, suburban)
- New Cairo (modern, malls, compounds)
- Downtown (central, historic)
- Giza (pyramids, university)

POPULAR PLACES:
Gyms: Gold's Gym (multiple locations), CrossFit Hustle, Wadi Degla, Iron House
Restaurants: Zooba (healthy Egyptian), Right Bite, Tabla Luna, On The Run
Running: Nile Corniche, Wadi Degla Sports Club trails, Cairo Runners group
Parks: Al-Azhar Park, Orman Garden

${hasHistory ? `\nConversation so far:\n${conversationHistory.map(m => `${m.role}: ${m.content}`).join('\n')}` : ''}

Remember: Keep it SHORT (under 60 words), use TAGS for scannability, and include quick reply options!`;
}

function parseAIResponse(rawText: string): EgyptGuideResponse {
  // Try to parse as JSON first
  const jsonMatch = rawText.match(/\{[\s\S]*\}/);
  if (jsonMatch) {
    try {
      const parsed = JSON.parse(jsonMatch[0]);
      return {
        text: parsed.text || rawText,
        suggestedPlaces: parsed.suggestedPlaces || [],
        tags: parsed.tags || [],
        quickReplies: parsed.quickReplies || [],
        elements: parsed.elements || []
      };
    } catch (e) {
      // If parsing fails, fall through to text-only
    }
  }

  // Fallback: treat as plain text
  return {
    text: rawText,
    suggestedPlaces: [],
    tags: [],
    quickReplies: []
  };
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

  const destination = body?.destination || 'Cairo';
  const conversationHistory = body?.conversationHistory || [];
  
  // Build conversation context for Gemini
  const systemPrompt = buildSystemPrompt(destination, conversationHistory);
  
  // Add current question to history
  const allMessages = [
    ...conversationHistory,
    { role: 'user', content: question }
  ];

  try {
    const geminiUrl = `https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=${GEMINI_KEY}`;
    
    // Build Gemini request with full conversation
    const geminiRes = await fetch(geminiUrl, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        contents: [
          {
            parts: [{ text: systemPrompt }]
          },
          {
            role: 'user',
            parts: [{ text: question }]
          }
        ],
        generationConfig: {
          temperature: 0.8,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 512, // Reduced for shorter responses
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
        JSON.stringify({ 
          text: "Oops! I had a moment there. Can you ask again? 🤔",
          quickReplies: [
            { id: "1", text: "Best gyms", emoji: "💪" },
            { id: "2", text: "Healthy food", emoji: "🥗" },
            { id: "3", text: "Running spots", emoji: "🏃" }
          ]
        }),
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

    if (!rawText) {
      return new Response(
        JSON.stringify({ 
          text: "Hmm, I'm drawing a blank. What are you looking for in Cairo? 🤔",
          quickReplies: [
            { id: "1", text: "Gyms", emoji: "💪", value: "Best gyms near me?" },
            { id: "2", text: "Restaurants", emoji: "🥗", value: "Healthy restaurants nearby?" },
            { id: "3", text: "Running", emoji: "🏃", value: "Running routes in Cairo?" }
          ]
        }),
        { status: 200, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
      );
    }

    // Parse the AI response
    const response = parseAIResponse(rawText);

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
    );
  } catch (err) {
    console.error("Server error:", err);
    return new Response(
      JSON.stringify({ 
        text: "Something went wrong! Let me help you get back on track. 💪",
        quickReplies: [
          { id: "1", text: "Find gyms", emoji: "💪" },
          { id: "2", text: "Find food", emoji: "🥗" }
        ]
      }),
      { status: 200, headers: { ...CORS_HEADERS, "content-type": "application/json" } }
    );
  }
}

Deno.serve(handler);

