// deno-lint-ignore-file no-explicit-any
// list_events_eventbrite: Search Eventbrite and return normalized events
// Method: POST
// Body JSON (all optional):
// {
//   "q": "yoga",
//   "lat": 40.7128,
//   "lon": -74.0060,
//   "radiusKm": 25,
//   "startDate": "2025-01-01T00:00:00Z",
//   "endDate": "2025-01-31T23:59:59Z",
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
  source: 'eventbrite';
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

    const token = Deno.env.get('EVENTBRITE_PRIVATE_TOKEN');
    if (!token) {
      return new Response(JSON.stringify({ error: 'Missing EVENTBRITE_PRIVATE_TOKEN' }), {
        status: 500,
        headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
      });
    }

    const url = new URL('https://www.eventbriteapi.com/v3/events/search/');
    url.searchParams.set('expand', 'venue');
    url.searchParams.set('sort_by', 'date');
    url.searchParams.set('page', String(page));
    url.searchParams.set('page_size', String(perPage));
    if (q) url.searchParams.set('q', String(q));
    if (startDate) url.searchParams.set('start_date.range_start', String(startDate));
    if (endDate) url.searchParams.set('start_date.range_end', String(endDate));
    if (lat && lon) {
      url.searchParams.set('location.latitude', String(lat));
      url.searchParams.set('location.longitude', String(lon));
      if (radiusKm) url.searchParams.set('location.within', `${radiusKm}km`);
    }

    const resp = await fetch(url.toString(), {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    });

    if (!resp.ok) {
      const text = await resp.text();
      return new Response(JSON.stringify({ error: 'Eventbrite API error', status: resp.status, body: text }), {
        status: 502,
        headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
      });
    }

    const data = await resp.json();
    const eventsRaw = Array.isArray(data?.events) ? data.events : [];

    const events: NormalizedEvent[] = eventsRaw.map((e: any) => {
      const venue = e?.venue ?? {};
      const addr = venue?.address ?? {};
      return {
        id: String(e?.id ?? ''),
        source: 'eventbrite',
        title: e?.name?.text ?? null,
        category: Array.isArray(e?.category) ? e.category?.[0]?.name ?? null : (e?.category?.name ?? null),
        start: e?.start?.utc ?? null,
        end: e?.end?.utc ?? null,
        venue: venue?.name ?? null,
        address: addr?.localized_address_display ?? null,
        lat: venue?.latitude ? Number(venue.latitude) : null,
        lon: venue?.longitude ? Number(venue.longitude) : null,
        url: e?.url ?? null,
        registrationUrl: e?.url ?? null,
        imageUrl: e?.logo?.url ?? null,
        city: addr?.city ?? null,
        state: addr?.region ?? null,
        country: addr?.country ?? null,
      };
    });

    const result = {
      provider: 'eventbrite',
      count: events.length,
      events,
      raw: { pagination: data?.pagination ?? null },
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
