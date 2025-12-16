// deno-lint-ignore-file no-explicit-any
// list_events_combined: Aggregates Eventbrite and RunSignup events with normalized schema
// Method: POST
// Body JSON (all optional):
// {
//   "q": "fitness",
//   "lat": 40.7128,
//   "lon": -74.0060,
//   "radiusKm": 25,
//   "startDate": "2025-01-01T00:00:00Z",
//   "endDate": "2025-01-31T23:59:59Z",
//   "page": 1,
//   "perPage": 40,
//   "providers": ["eventbrite", "runsignup"]
// }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

type Provider = 'eventbrite' | 'runsignup';

interface NormalizedEvent {
  id: string;
  source: Provider;
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

async function fetchEventbrite(params: any): Promise<NormalizedEvent[]> {
  const {
    q, lat, lon, radiusKm, startDate, endDate, page = 1, perPage = 40
  } = params;
  const token = Deno.env.get('EVENTBRITE_PRIVATE_TOKEN');
  if (!token) return [];

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
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
  });
  if (!resp.ok) return [];
  const data = await resp.json();
  const eventsRaw = Array.isArray(data?.events) ? data.events : [];
  return eventsRaw.map((e: any) => {
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
    } as NormalizedEvent;
  });
}

async function fetchRunSignup(params: any): Promise<NormalizedEvent[]> {
  const { q, lat, lon, radiusKm, startDate, endDate, page = 1, perPage = 40 } = params;
  const apiKey = Deno.env.get('RUNSIGNUP_API_KEY');
  const apiSecret = Deno.env.get('RUNSIGNUP_API_SECRET');
  if (!apiKey || !apiSecret) return [];

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

  const auth = btoa(`${apiKey}:${apiSecret}`);
  const resp = await fetch(url.toString(), {
    headers: { 'Authorization': `Basic ${auth}`, 'Content-Type': 'application/json' },
  });
  if (!resp.ok) return [];
  const data = await resp.json();
  const racesRaw = Array.isArray(data?.races) ? data.races : [];
  return racesRaw.map((r: any) => {
    const race = r?.race ?? r;
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
    } as NormalizedEvent;
  });
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
    const body = await req.json().catch(() => ({}));
    const { providers = ['eventbrite', 'runsignup'], ...params } = body;

    const useEventbrite = (providers as Provider[]).includes('eventbrite');
    const useRunSignup = (providers as Provider[]).includes('runsignup');

    const [eb, rs] = await Promise.all([
      useEventbrite ? fetchEventbrite(params).catch(() => []) : Promise.resolve([]),
      useRunSignup ? fetchRunSignup(params).catch(() => []) : Promise.resolve([]),
    ]);

    // Simple de-dup by URL or title+date heuristic
    const all = [...eb, ...rs];
    const seen = new Set<string>();
    const deduped: NormalizedEvent[] = [];
    for (const e of all) {
      const key = (e.url ?? e.registrationUrl ?? `${e.title}|${e.start}`);
      if (!key) { deduped.push(e); continue; }
      if (seen.has(key)) continue;
      seen.add(key);
      deduped.push(e);
    }

    // Sort by start datetime ascending
    deduped.sort((a, b) => {
      const ta = a.start ? Date.parse(a.start) : 0;
      const tb = b.start ? Date.parse(b.start) : 0;
      return ta - tb;
    });

    return new Response(JSON.stringify({
      providers_used: {
        eventbrite: eb.length,
        runsignup: rs.length,
      },
      count: deduped.length,
      events: deduped,
    }), {
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message ?? 'Unknown error' }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }
});
