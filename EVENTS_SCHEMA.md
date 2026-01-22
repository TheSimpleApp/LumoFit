# Events Table Schema for Supabase

This document describes the required Supabase schema for the events feature with n8n webhook integration.

## Table: `events`

```sql
CREATE TABLE IF NOT EXISTS events (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'other',
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  description TEXT,
  venue_name TEXT NOT NULL DEFAULT 'TBA',
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  website_url TEXT,
  registration_url TEXT,
  image_url TEXT,
  source TEXT,
  city TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS events_start_date_idx ON events(start_date);
CREATE INDEX IF NOT EXISTS events_city_idx ON events(city);
CREATE INDEX IF NOT EXISTS events_location_idx ON events(latitude, longitude);
```

## Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | TEXT | Yes | Unique identifier (generated from title_date_location) |
| `title` | TEXT | Yes | Event title |
| `category` | TEXT | Yes | Event category (running, yoga, hiking, etc.) |
| `start_date` | TIMESTAMPTZ | Yes | Event start date/time |
| `end_date` | TIMESTAMPTZ | No | Event end date/time |
| `description` | TEXT | No | Event description |
| `venue_name` | TEXT | Yes | Venue or organizer name |
| `address` | TEXT | No | Full address |
| `latitude` | DOUBLE PRECISION | No | Latitude coordinate |
| `longitude` | DOUBLE PRECISION | No | Longitude coordinate |
| `website_url` | TEXT | No | Event website URL |
| `registration_url` | TEXT | No | Registration link |
| `image_url` | TEXT | No | Event image URL |
| `source` | TEXT | No | Data source identifier |
| `city` | TEXT | No | City name for filtering |
| `created_at` | TIMESTAMPTZ | Auto | Record creation timestamp |
| `updated_at` | TIMESTAMPTZ | Auto | Record update timestamp |

## Event Categories

Supported categories (must match EventCategory enum in `event_model.dart`):
- `running`
- `yoga`
- `hiking`
- `cycling`
- `crossfit`
- `bootcamp`
- `swimming`
- `groupFitness`
- `triathlon`
- `obstacle`
- `other`

## n8n Webhook Integration

### Webhook URL
```
https://thesimpleapp.app.n8n.cloud/webhook/lifestyle-events
```

### Request Format
```json
{
  "location": "Salt Lake City, UT, USA",
  "latitude": 40.7608,
  "longitude": -111.8910
}
```

### Response Format
```json
{
  "events": [
    {
      "title": "SLRC Thursday Group Run",
      "description": "A weekly group run for all paces...",
      "images": [],
      "source_url": "https://saltlakerunning.com/group-runs",
      "tags": ["running", "run club", "social"],
      "details": {
        "date": "2026-01-22",
        "time": "6:00 PM",
        "location": "Salt Lake Running Company, 2454 S 700 E, Salt Lake City, UT 84106",
        "price": "Free",
        "organizer": "Salt Lake Running Company"
      }
    }
  ],
  "metadata": {
    "location": "Salt Lake City, UT, USA",
    "date_range": "2026-01-22 to 2026-01-31",
    "total_found": 4
  }
}
```

## Deduplication Strategy

Events are deduplicated using a composite ID generated from:
```
{title_lowercase}_{date}_{location_lowercase}
```

All non-alphanumeric characters are replaced with underscores.

The `upsert` operation with `onConflict: 'id'` ensures that duplicate events are updated rather than creating new records.

## RLS Policies (Row Level Security)

For public read access to events:

```sql
-- Enable RLS
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Allow public read access
CREATE POLICY "Events are viewable by everyone"
  ON events FOR SELECT
  USING (true);

-- Allow authenticated users to insert/update events
CREATE POLICY "Authenticated users can insert events"
  ON events FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update events"
  ON events FOR UPDATE
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');
```

## Usage Flow

1. User searches for a location on the map
2. User taps "Find Events Here" button
3. App calls n8n webhook with location data
4. n8n webhook responds with discovered events (typically 15-20 seconds)
5. App parses response and saves events to Supabase with deduplication
6. App reloads events from Supabase and displays on map
7. User can view events on map (purple markers) or in Discover tab

## Implementation Files

- **Service**: `lib/services/event_service.dart`
  - `discoverEventsForLocation()` - Main webhook integration
  - `_saveDiscoveredEvents()` - Parse and save to Supabase
  - `_loadEventsFromSupabase()` - Load from database

- **UI**: `lib/screens/map/map_screen.dart`
  - "Find Events Here" button with loading state
  - Event markers on map (royal purple)
  - Auto-reload after successful discovery

- **Model**: `lib/models/event_model.dart`
  - Event data structure
  - Category enums and parsing
