# OpenMemory

## Overview
- LumoFit is a Flutter 3.6+ mobile app focused on fitness travel discovery.
- State management uses Provider and navigation uses GoRouter.
- Backend services use Supabase (PostgreSQL, Auth, Storage, Edge Functions).
- Map/places are powered by Google Maps and Google Places APIs.

## Architecture
- Entry point: `lib/main.dart`
- Routes: `lib/nav.dart`
- Theme: `lib/theme.dart` (dark luxury theme with custom colors)
- Screens live under `lib/screens/` by feature area.
- Business logic in `lib/services/` with ChangeNotifier patterns.

## User Defined Namespaces
- 

## Components
- Trips: `lib/screens/trips/trips_screen.dart` (trip list + create trip bottom sheet)
- Trip detail: `lib/screens/trips/trip_detail_screen.dart` (trip detail + edit trip bottom sheet)

## Patterns
- Bottom sheets are constrained by max height and wrap content with SafeArea + scroll.