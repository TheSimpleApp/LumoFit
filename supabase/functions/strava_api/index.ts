import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const STRAVA_CLIENT_ID = Deno.env.get("STRAVA_CLIENT_ID");
const STRAVA_CLIENT_SECRET = Deno.env.get("STRAVA_CLIENT_SECRET");
const STRAVA_API_BASE = "https://www.strava.com/api/v3";

interface StravaRequest {
  action: "token_exchange" | "refresh_token" | "explore_segments" | "get_clubs" | "get_athlete";
  code?: string;
  refreshToken?: string;
  accessToken?: string;
  bounds?: { swLat: number; swLng: number; neLat: number; neLng: number };
  activityType?: "running" | "riding";
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
    const body: StravaRequest = await req.json();

    if (!STRAVA_CLIENT_ID || !STRAVA_CLIENT_SECRET) {
      return new Response(
        JSON.stringify({ error: "Strava credentials not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    switch (body.action) {
      case "token_exchange": {
        // Exchange authorization code for access token
        if (!body.code) {
          return new Response(
            JSON.stringify({ error: "Authorization code required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const response = await fetch("https://www.strava.com/oauth/token", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            client_id: STRAVA_CLIENT_ID,
            client_secret: STRAVA_CLIENT_SECRET,
            code: body.code,
            grant_type: "authorization_code",
          }),
        });

        const data = await response.json();
        return new Response(JSON.stringify(data), {
          status: response.ok ? 200 : response.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "refresh_token": {
        // Refresh expired access token
        if (!body.refreshToken) {
          return new Response(
            JSON.stringify({ error: "Refresh token required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const response = await fetch("https://www.strava.com/oauth/token", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            client_id: STRAVA_CLIENT_ID,
            client_secret: STRAVA_CLIENT_SECRET,
            refresh_token: body.refreshToken,
            grant_type: "refresh_token",
          }),
        });

        const data = await response.json();
        return new Response(JSON.stringify(data), {
          status: response.ok ? 200 : response.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "explore_segments": {
        // Explore segments in geographic bounds
        if (!body.accessToken || !body.bounds) {
          return new Response(
            JSON.stringify({ error: "Access token and bounds required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const { swLat, swLng, neLat, neLng } = body.bounds;
        const activityType = body.activityType || "running";

        const response = await fetch(
          `${STRAVA_API_BASE}/segments/explore?bounds=${swLat},${swLng},${neLat},${neLng}&activity_type=${activityType}`,
          {
            headers: { "Authorization": `Bearer ${body.accessToken}` },
          }
        );

        const data = await response.json();
        return new Response(JSON.stringify(data), {
          status: response.ok ? 200 : response.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "get_clubs": {
        // Get athlete's clubs
        if (!body.accessToken) {
          return new Response(
            JSON.stringify({ error: "Access token required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const response = await fetch(`${STRAVA_API_BASE}/athlete/clubs`, {
          headers: { "Authorization": `Bearer ${body.accessToken}` },
        });

        const data = await response.json();
        return new Response(JSON.stringify(data), {
          status: response.ok ? 200 : response.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "get_athlete": {
        // Get authenticated athlete profile
        if (!body.accessToken) {
          return new Response(
            JSON.stringify({ error: "Access token required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const response = await fetch(`${STRAVA_API_BASE}/athlete`, {
          headers: { "Authorization": `Bearer ${body.accessToken}` },
        });

        const data = await response.json();
        return new Response(JSON.stringify(data), {
          status: response.ok ? 200 : response.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      default:
        return new Response(
          JSON.stringify({ error: "Unknown action" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
  } catch (error) {
    console.error("Error in strava_api:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: String(error) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
