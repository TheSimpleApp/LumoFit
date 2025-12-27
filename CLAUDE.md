# Claude Code Project Instructions

## Critical: Avoid Hallucinating About Current Technology

**ALWAYS verify before claiming something doesn't exist or isn't available.**

### AI Models - Current State (December 2024+)
Before stating any AI model "doesn't exist" or "isn't available", use WebSearch to verify. The AI landscape changes rapidly.

**Known Available Models (verify for latest):**
- **Gemini:** 2.0 Flash, 2.5 Flash, 2.5 Pro, Gemini Ultra (check Google AI for current versions)
- **OpenAI:** GPT-4, GPT-4 Turbo, GPT-4o, o1, o1-mini (check OpenAI for current versions)
- **Anthropic:** Claude 3 Opus, Claude 3.5 Sonnet, Claude Opus 4.5 (check Anthropic for current versions)
- **Other:** Llama 3, Mistral, Mixtral, Grok, etc.

### Before Making Claims About Technology
1. **DO NOT** claim an API, model, or feature doesn't exist without checking
2. **DO** use WebSearch to verify current availability when uncertain
3. **DO** check official documentation (Google AI Studio, OpenAI docs, etc.)
4. Knowledge cutoffs mean your training data may be outdated - always verify

### This Project Uses
- **Gemini 2.5 Flash** - Confirmed working in Edge Functions (see `supabase/functions/`)
- Model ID: `gemini-2.5-flash`
- API endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`

---

## Project Overview

FitTravel is a Flutter fitness travel app with a Supabase backend, targeting Cairo, Egypt for beta.

### Key Files
- `knowledge.md` - Comprehensive project documentation
- `lib/services/` - All backend service integrations
- `supabase/functions/` - Edge Functions (AI integrations)

### Tech Stack
- **Frontend:** Flutter/Dart
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **AI:** Gemini 2.5 Flash via Edge Functions
- **Maps:** Google Maps Flutter SDK
- **APIs:** Google Places API

### Edge Functions (AI-Powered)
1. `cairo_guide` - Cairo-specific fitness AI assistant
2. `egypt_fitness_guide` - Egypt-wide AI concierge (8 destinations)
3. `get_place_insights` - AI-generated place tips with caching
4. `generate_fitness_itinerary` - AI day planner

### Development Notes
- Always check `knowledge.md` for current architecture
- API keys are stored in Supabase Edge Function environment variables
- Default location is Cairo (30.0444, 31.2357)
- App uses dark luxury aesthetic with gold accents

---

## Coding Standards

### Flutter/Dart
- Use Provider for state management
- Services extend ChangeNotifier
- Follow existing patterns in `lib/services/`

### Supabase Edge Functions
- Written in TypeScript/Deno
- Use environment variables for API keys
- Follow existing patterns in `supabase/functions/`

### When Updating AI Integrations
1. Verify model availability with WebSearch first
2. Check Google AI documentation for latest model IDs
3. Test in Edge Function before committing
