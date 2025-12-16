// deno-lint-ignore-file no-explicit-any
// list_events_runsignup: Search RunSignup races and return normalized events
// Method: POST
// Body JSON (all optional):
// {
//   "q": "5k",
//   "lat": 40.7128,
//   "lon": -74.0060,
//   "radiusKm": 50,
//   "startDate": "2025-01-01",
//   "endDate": "2025-01-31",
//   "page": 1,
//   "perPage": 50
// }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

interface NormalizedEvent {
  id: string;
  source: 'runsignup';
  title: string;
  category?: string | null;
  start: string | null;
  end?: string | null;
  venue?: string | null;
  address?: string | null;
  lat?: number | null;
  lon?: number | null;
  url?: string | null;
  registrationUrl?: string | null;
  imageUrl?: string | null;
  city?: string | null;
  state?: string | null;
  country?: string | null;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  try {
    const { q, lat, lon, radiusKm, startDate, endDate, page = 1, perPage = 50 } = await req.json().catch(() => ({}));

    const apiKey = Deno.env.get('RUNSIGNUP_API_KEY');
    const apiSecret = Deno.env.get('RUNSIGNUP_API_SECRET');

    if (!apiKey || !apiSecret) {
      // Credentials not set yet — return empty results with a hint.
      return new Response(JSON.stringify({
        provider: 'runsignup',
        count: 0,
        events: [],
        note: 'RUNSIGNUP_API_KEY / RUNSIGNUP_API_SECRET not configured; skipping provider.'
      }), {
        headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
      });
    }

    // Build query — RunSignup supports a variety of filters. We'll use a simple name/geo/date filter when possible.
    const url = new URL('https://runsignup.com/rest/races');
    url.searchParams.set('format', 'json');
    if (q) url.searchParams.set('name', String(q));
    if (startDate) url.searchParams.set('start_date', String(startDate));
    if (endDate) url.searchParams.set('end_date', String(endDate));
    if (lat && lon) {
      url.searchParams.set('lat', String(lat));
      url.searchParams.set('long', String(lon));
      if (radiusKm) url.searchParams.set('radius', String(radiusKm));
    }
    url.searchParams.set('page', String(page));
    url.searchParams.set('results_per_page', String(perPage));

    // RunSignup uses HTTP Basic with api_key:api_secret, or query params. We'll use Basic.
    const auth = btoa(`${apiKey}:${apiSecret}`);

    const resp = await fetch(url.toString(), {
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/json',
      }
    });

    if (!resp.ok) {
      const text = await resp.text();
      return new Response(JSON.stringify({ error: 'RunSignup API error', status: resp.status, body: text }), {
        status: 502,
        headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
      });
    }

    const data = await resp.json();
    const racesRaw = Array.isArray(data?.races) ? data.races : [];

    const events: NormalizedEvent[] = racesRaw.map((r: any) => {
      const race = r?.race ?? r; // some responses embed race
      const point = race?.location ?? race?.geo ?? {};
      const addr = race?.address ?? {};
      const nextEvent = Array.isArray(race?.events) ? race.events[0] : null;
      return {
        id: String(race?.race_id ?? race?.id ?? ''),
        source: 'runsignup',
        title: race?.name ?? null,
        category: 'race',
        start: nextEvent?.start_time ?? race?.next_date ?? null,
        end: null,
        venue: race?.name ?? null,
        address: addr?.street ?? null,
        lat: point?.lat ? Number(point.lat) : null,
        lon: point?.lng ? Number(point.lng) : null,
        url: race?.url ?? null,
        registrationUrl: race?.registration_url ?? race?.url ?? null,
        imageUrl: (Array.isArray(race?.images) && race.images[0]?.url) ? race.images[0].url : null,
        city: addr?.city ?? null,
        state: addr?.state ?? null,
        country: addr?.country ?? null,
      };
    });

    const result = {
      provider: 'runsignup',
      count: events.length,
      events,
    };

    return new Response(JSON.stringify(result), {
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message ?? 'Unknown error' }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }
});
