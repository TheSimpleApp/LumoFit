-- Create table for caching AI fitness intelligence analysis
-- This reduces API costs and improves performance

CREATE TABLE IF NOT EXISTS place_fitness_intelligence_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id TEXT NOT NULL,
  place_name TEXT NOT NULL,
  place_type TEXT NOT NULL,
  intelligence JSONB NOT NULL,
  reviews_analyzed INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookups by place_id
CREATE INDEX IF NOT EXISTS idx_place_fitness_cache_place_id 
  ON place_fitness_intelligence_cache(place_id);

-- Index for cache expiration queries
CREATE INDEX IF NOT EXISTS idx_place_fitness_cache_created_at 
  ON place_fitness_intelligence_cache(created_at DESC);

-- Composite index for place_id + created_at (for cache hit queries)
CREATE INDEX IF NOT EXISTS idx_place_fitness_cache_lookup 
  ON place_fitness_intelligence_cache(place_id, created_at DESC);

-- Enable Row Level Security
ALTER TABLE place_fitness_intelligence_cache ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read cached intelligence (public data)
CREATE POLICY "Public read access to fitness intelligence cache"
  ON place_fitness_intelligence_cache
  FOR SELECT
  USING (true);

-- Policy: Only service role can insert/update cache
CREATE POLICY "Service role can manage fitness intelligence cache"
  ON place_fitness_intelligence_cache
  FOR ALL
  USING (auth.role() = 'service_role');

-- Function to clean up old cache entries (older than 7 days)
CREATE OR REPLACE FUNCTION cleanup_old_fitness_intelligence_cache()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM place_fitness_intelligence_cache
  WHERE created_at < NOW() - INTERVAL '7 days';
END;
$$;

-- Comment on table
COMMENT ON TABLE place_fitness_intelligence_cache IS 
  'Caches AI-generated fitness intelligence for places to reduce API costs and improve performance. TTL: 24 hours for cache hits, 7 days for cleanup.';

