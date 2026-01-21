# LumoFit + Composio SDK Integration Plan

> **Created:** January 20, 2026  
> **Status:** 🟡 Planning Phase  
> **Target Completion:** Q1 2026

## 📋 Executive Summary

This document outlines the complete integration plan for adding Composio SDK to LumoFit, enabling users to connect their fitness accounts (Strava, Apple Health, Google Fit) and calendar apps for a seamless active lifestyle experience.

### Quick Stats
- **Integrations Planned:** 5 major platforms
- **Estimated Development Time:** 4-6 weeks
- **Expected Monthly Cost:** ~$50-150 (based on 1,000-5,000 active users)
- **User Value:** Personalized fitness tracking + automatic calendar sync

---

## 🎯 Integration Strategy

### Hybrid Architecture

```
┌──────────────────────────────────────────────────────┐
│              LumoFit Flutter App                     │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │   USER-SPECIFIC (Composio SDK)             │    │
│  │                                            │    │
│  │  ✅ Strava - Activity sync                 │    │
│  │  ✅ Google Calendar - Event management     │    │
│  │  ✅ Apple Health - Health data sync        │    │
│  │  ✅ Google Fit - Android fitness tracking  │    │
│  │  ✅ Garmin - Device sync (future)          │    │
│  │                                            │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │   GLOBAL/SHARED (Keep Existing)            │    │
│  │                                            │    │
│  │  📍 Event Search (Eventbrite, RunSignup)   │    │
│  │  🗺️  Google Maps (Public places)           │    │
│  │  ☁️  Weather API                            │    │
│  │                                            │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**Why Hybrid?**
- **Composio SDK**: User-specific, authenticated data (workouts, calendars)
- **Direct APIs**: Public, shared data (events, places) - more cost-effective
- **Best of Both**: Optimized for user experience AND operating costs

---

## 🏗️ Technical Architecture

### 1. Project Structure

```
lib/
├── composio/
│   ├── composio_service.dart          # Core Composio SDK wrapper
│   ├── entity_manager.dart            # User entity management
│   └── integrations/
│       ├── strava_integration.dart    # Strava-specific logic
│       ├── calendar_integration.dart  # Google Calendar logic
│       ├── health_integration.dart    # Apple Health/Google Fit
│       └── base_integration.dart      # Shared integration interface
├── models/
│   ├── activity_model.dart            # Enhanced with Strava data
│   ├── calendar_event_model.dart      # Calendar event model
│   └── health_data_model.dart         # Health metrics model
├── screens/
│   ├── settings/
│   │   ├── integrations_screen.dart   # Connect apps UI
│   │   └── widgets/
│   │       ├── connection_card.dart   # Individual app card
│   │       └── sync_status_widget.dart # Sync status indicator
│   └── profile/
│       └── activity_history_screen.dart # Synced activities
└── services/
    ├── sync_service.dart              # Background sync orchestrator
    └── cache_service.dart             # Cache synced data
```

### 2. Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  # Composio SDK
  composio_flutter: ^1.0.0  # Check latest version
  
  # Additional helpers
  flutter_secure_storage: ^9.2.2  # Already included
  connectivity_plus: ^5.0.0       # Check network status
  workmanager: ^0.5.0             # Background sync
  
  # Health integrations
  health: ^10.0.0                 # Apple Health / Google Fit
```

### 3. Environment Variables

Create `.env` file (add to `.gitignore`):

```bash
# Composio API Key (get from https://app.composio.dev)
COMPOSIO_API_KEY=your_api_key_here

# Base URL (default: https://backend.composio.dev)
COMPOSIO_BASE_URL=https://backend.composio.dev

# Entity prefix (optional, for multi-tenant)
COMPOSIO_ENTITY_PREFIX=lumofit_
```

Update `lib/config/app_config.dart`:

```dart
class AppConfig {
  // ... existing config ...
  
  // Composio configuration
  static const String composioApiKey = String.fromEnvironment(
    'COMPOSIO_API_KEY',
    defaultValue: '',
  );
  
  static const String composioBaseUrl = String.fromEnvironment(
    'COMPOSIO_BASE_URL',
    defaultValue: 'https://backend.composio.dev',
  );
}
```

---

## 🔌 Integration Details

### Phase 1: Foundation (Week 1-2)

#### 1.1 Composio Service Setup

**File:** `lib/composio/composio_service.dart`

```dart
import 'package:composio_flutter/composio_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ComposioService {
  static final ComposioService _instance = ComposioService._internal();
  factory ComposioService() => _instance;
  ComposioService._internal();

  late Composio _composio;
  final _storage = const FlutterSecureStorage();

  Future<void> initialize() async {
    _composio = Composio(
      apiKey: AppConfig.composioApiKey,
      baseUrl: AppConfig.composioBaseUrl,
    );
  }

  /// Generate entity ID for user
  String getEntityId(String userId) {
    return 'lumofit_$userId';
  }

  /// Initiate connection for a user
  Future<ConnectionResult> initiateConnection({
    required String userId,
    required String app, // 'strava', 'googlecalendar', etc.
    String? redirectUrl,
  }) async {
    try {
      final result = await _composio.getConnectionRequest(
        app: app,
        entityId: getEntityId(userId),
        redirectUrl: redirectUrl ?? 'lumofit://auth-callback',
      );
      
      return ConnectionResult(
        success: true,
        redirectUrl: result.redirectUrl,
        connectionId: result.connectionId,
      );
    } catch (e) {
      debugPrint('Composio connection error: $e');
      return ConnectionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Check connection status
  Future<bool> isConnected({
    required String userId,
    required String app,
  }) async {
    try {
      final connections = await _composio.getConnections(
        entityId: getEntityId(userId),
        app: app,
      );
      
      return connections.isNotEmpty && 
             connections.first.status == 'ACTIVE';
    } catch (e) {
      debugPrint('Check connection error: $e');
      return false;
    }
  }

  /// Execute action for user
  Future<dynamic> execute({
    required String userId,
    required String action,
    Map<String, dynamic>? params,
  }) async {
    try {
      final result = await _composio.execute(
        action: action,
        entityId: getEntityId(userId),
        params: params ?? {},
      );
      
      return result;
    } catch (e) {
      debugPrint('Execute action error: $e');
      rethrow;
    }
  }

  /// Disconnect app
  Future<void> disconnect({
    required String userId,
    required String app,
  }) async {
    await _composio.deleteConnection(
      entityId: getEntityId(userId),
      app: app,
    );
  }
}

class ConnectionResult {
  final bool success;
  final String? redirectUrl;
  final String? connectionId;
  final String? error;

  ConnectionResult({
    required this.success,
    this.redirectUrl,
    this.connectionId,
    this.error,
  });
}
```

#### 1.2 Entity Manager

**File:** `lib/composio/entity_manager.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EntityManager {
  final _storage = const FlutterSecureStorage();
  final _composio = ComposioService();

  /// Store connection metadata
  Future<void> saveConnection({
    required String userId,
    required String app,
    required String connectionId,
  }) async {
    final key = 'composio_${app}_$userId';
    await _storage.write(
      key: key,
      value: jsonEncode({
        'connectionId': connectionId,
        'connectedAt': DateTime.now().toIso8601String(),
        'app': app,
      }),
    );
  }

  /// Get connection info
  Future<Map<String, dynamic>?> getConnection({
    required String userId,
    required String app,
  }) async {
    final key = 'composio_${app}_$userId';
    final data = await _storage.read(key: key);
    if (data == null) return null;
    
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// Remove connection
  Future<void> removeConnection({
    required String userId,
    required String app,
  }) async {
    final key = 'composio_${app}_$userId';
    await _storage.delete(key: key);
  }

  /// Get all connected apps for user
  Future<List<String>> getConnectedApps(String userId) async {
    final all = await _storage.readAll();
    final prefix = 'composio_';
    final suffix = '_$userId';
    
    return all.keys
        .where((k) => k.startsWith(prefix) && k.endsWith(suffix))
        .map((k) => k.substring(prefix.length, k.length - suffix.length))
        .toList();
  }
}
```

---

### Phase 2: Strava Integration (Week 2-3)

#### 2.1 Strava Integration Service

**File:** `lib/composio/integrations/strava_integration.dart`

```dart
import 'package:fittravel/composio/composio_service.dart';
import 'package:fittravel/models/activity_model.dart';

class StravaIntegration {
  final _composio = ComposioService();

  /// Connect user's Strava account
  Future<ConnectionResult> connect(String userId) async {
    return await _composio.initiateConnection(
      userId: userId,
      app: 'strava',
      redirectUrl: 'lumofit://strava-callback',
    );
  }

  /// Check if connected
  Future<bool> isConnected(String userId) async {
    return await _composio.isConnected(
      userId: userId,
      app: 'strava',
    );
  }

  /// Fetch recent activities
  Future<List<ActivityModel>> fetchActivities({
    required String userId,
    DateTime? after,
    int perPage = 50,
  }) async {
    final afterTimestamp = after != null
        ? (after.millisecondsSinceEpoch ~/ 1000)
        : (DateTime.now().subtract(Duration(days: 30)).millisecondsSinceEpoch ~/ 1000);

    final result = await _composio.execute(
      userId: userId,
      action: 'STRAVA_GET_LOGGED_IN_ATHLETE_ACTIVITIES',
      params: {
        'per_page': perPage,
        'after': afterTimestamp,
      },
    );

    final List<dynamic> activities = result['data'] ?? [];
    return activities
        .map((json) => ActivityModel.fromStravaJson(json))
        .toList();
  }

  /// Get athlete profile
  Future<AthleteProfile?> getAthleteProfile(String userId) async {
    try {
      final result = await _composio.execute(
        userId: userId,
        action: 'STRAVA_GET_LOGGED_IN_ATHLETE',
      );

      return AthleteProfile.fromJson(result['data']);
    } catch (e) {
      debugPrint('Get athlete profile error: $e');
      return null;
    }
  }

  /// Sync activities to local database
  Future<int> syncActivities(String userId) async {
    final activities = await fetchActivities(userId: userId);
    
    // Save to Supabase/local database
    for (final activity in activities) {
      await _saveActivityToDatabase(activity, userId);
    }
    
    return activities.length;
  }

  Future<void> _saveActivityToDatabase(
    ActivityModel activity,
    String userId,
  ) async {
    // TODO: Implement database save
    // await SupabaseConfig.client.from('user_activities').upsert({
    //   'user_id': userId,
    //   'strava_id': activity.id,
    //   'type': activity.type,
    //   'distance': activity.distance,
    //   'duration': activity.duration,
    //   'started_at': activity.startedAt.toIso8601String(),
    //   'synced_at': DateTime.now().toIso8601String(),
    // });
  }
}

class AthleteProfile {
  final String id;
  final String username;
  final String? firstname;
  final String? lastname;
  final String? profileImageUrl;

  AthleteProfile({
    required this.id,
    required this.username,
    this.firstname,
    this.lastname,
    this.profileImageUrl,
  });

  factory AthleteProfile.fromJson(Map<String, dynamic> json) {
    return AthleteProfile(
      id: json['id'].toString(),
      username: json['username'] as String,
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      profileImageUrl: json['profile'] as String?,
    );
  }
}
```

#### 2.2 Update Activity Model

**File:** `lib/models/activity_model.dart` (enhance existing)

```dart
// Add to existing ActivityModel class

class ActivityModel {
  // ... existing fields ...
  
  // New fields for Strava integration
  final String? stravaId;
  final String? sourceApp; // 'strava', 'manual', 'apple_health'
  final DateTime? syncedAt;
  
  // Add factory constructor for Strava data
  factory ActivityModel.fromStravaJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: const Uuid().v4(),
      stravaId: json['id'].toString(),
      sourceApp: 'strava',
      type: _mapStravaType(json['type'] as String?),
      name: json['name'] as String? ?? 'Workout',
      distance: (json['distance'] as num?)?.toDouble(),
      duration: Duration(seconds: json['moving_time'] as int? ?? 0),
      startedAt: DateTime.parse(json['start_date'] as String),
      location: json['location_city'] as String?,
      calories: (json['calories'] as num?)?.toDouble(),
      avgHeartRate: (json['average_heartrate'] as num?)?.toDouble(),
      syncedAt: DateTime.now(),
    );
  }
  
  static ActivityType _mapStravaType(String? type) {
    switch (type?.toLowerCase()) {
      case 'run':
        return ActivityType.running;
      case 'ride':
        return ActivityType.cycling;
      case 'swim':
        return ActivityType.swimming;
      case 'hike':
        return ActivityType.hiking;
      case 'yoga':
        return ActivityType.yoga;
      case 'workout':
      case 'weighttraining':
        return ActivityType.crossfit;
      default:
        return ActivityType.other;
    }
  }
}
```

---

### Phase 3: Google Calendar Integration (Week 3-4)

#### 3.1 Calendar Integration Service

**File:** `lib/composio/integrations/calendar_integration.dart`

```dart
import 'package:fittravel/composio/composio_service.dart';
import 'package:fittravel/models/event_model.dart';

class CalendarIntegration {
  final _composio = ComposioService();

  /// Connect user's Google Calendar
  Future<ConnectionResult> connect(String userId) async {
    return await _composio.initiateConnection(
      userId: userId,
      app: 'googlecalendar',
      redirectUrl: 'lumofit://calendar-callback',
    );
  }

  /// Check if connected
  Future<bool> isConnected(String userId) async {
    return await _composio.isConnected(
      userId: userId,
      app: 'googlecalendar',
    );
  }

  /// Add event to user's calendar
  Future<CalendarEventResult> addEventToCalendar({
    required String userId,
    required EventModel event,
    bool createMeetLink = false,
  }) async {
    try {
      final result = await _composio.execute(
        userId: userId,
        action: 'GOOGLECALENDAR_CREATE_EVENT',
        params: {
          'calendar_id': 'primary',
          'summary': event.title,
          'start_datetime': event.start.toIso8601String(),
          'event_duration_hour': event.end != null
              ? event.end!.difference(event.start).inHours
              : 2,
          'event_duration_minutes': event.end != null
              ? event.end!.difference(event.start).inMinutes % 60
              : 0,
          'location': event.address ?? event.venueName,
          'description': _buildEventDescription(event),
          'timezone': 'America/Denver', // Use user's timezone
          'create_meeting_room': createMeetLink,
        },
      );

      return CalendarEventResult(
        success: true,
        eventId: result['data']['id'] as String,
        htmlLink: result['data']['htmlLink'] as String?,
      );
    } catch (e) {
      debugPrint('Add event to calendar error: $e');
      return CalendarEventResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Check if user is available at event time
  Future<bool> checkAvailability({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final result = await _composio.execute(
        userId: userId,
        action: 'GOOGLECALENDAR_FIND_FREE_SLOTS',
        params: {
          'items': ['primary'],
          'time_min': start.toIso8601String(),
          'time_max': end.toIso8601String(),
        },
      );

      final calendars = result['data']['calendars'] as Map<String, dynamic>;
      final primaryCalendar = calendars['primary'] as Map<String, dynamic>;
      final busy = primaryCalendar['busy'] as List;
      
      return busy.isEmpty; // User is free if no busy periods
    } catch (e) {
      debugPrint('Check availability error: $e');
      return true; // Assume available on error
    }
  }

  String _buildEventDescription(EventModel event) {
    final buffer = StringBuffer();
    
    if (event.description != null) {
      buffer.writeln(event.description);
      buffer.writeln();
    }
    
    buffer.writeln('📍 ${event.venueName}');
    if (event.address != null) {
      buffer.writeln(event.address);
    }
    
    if (event.websiteUrl != null) {
      buffer.writeln();
      buffer.writeln('🌐 Event Website: ${event.websiteUrl}');
    }
    
    if (event.registrationUrl != null) {
      buffer.writeln('🎫 Register: ${event.registrationUrl}');
    }
    
    buffer.writeln();
    buffer.writeln('Added by LumoFit 🏃');
    
    return buffer.toString();
  }
}

class CalendarEventResult {
  final bool success;
  final String? eventId;
  final String? htmlLink;
  final String? error;

  CalendarEventResult({
    required this.success,
    this.eventId,
    this.htmlLink,
    this.error,
  });
}
```

---

### Phase 4: UI Implementation (Week 4-5)

#### 4.1 Integrations Screen

**File:** `lib/screens/settings/integrations_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:fittravel/composio/integrations/strava_integration.dart';
import 'package:fittravel/composio/integrations/calendar_integration.dart';
import 'package:url_launcher/url_launcher.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({Key? key}) : super(key: key);

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  final _stravaIntegration = StravaIntegration();
  final _calendarIntegration = CalendarIntegration();
  
  bool _stravaConnected = false;
  bool _calendarConnected = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkConnections();
  }

  Future<void> _checkConnections() async {
    final userId = getCurrentUserId(); // Get from auth
    
    setState(() => _loading = true);
    
    _stravaConnected = await _stravaIntegration.isConnected(userId);
    _calendarConnected = await _calendarIntegration.isConnected(userId);
    
    setState(() => _loading = false);
  }

  Future<void> _connectStrava() async {
    final userId = getCurrentUserId();
    final result = await _stravaIntegration.connect(userId);
    
    if (result.success && result.redirectUrl != null) {
      // Open OAuth URL
      await launchUrl(
        Uri.parse(result.redirectUrl!),
        mode: LaunchMode.externalApplication,
      );
      
      // Show instructions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete authorization in browser, then return here'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _connectCalendar() async {
    final userId = getCurrentUserId();
    final result = await _calendarIntegration.connect(userId);
    
    if (result.success && result.redirectUrl != null) {
      await launchUrl(
        Uri.parse(result.redirectUrl!),
        mode: LaunchMode.externalApplication,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete authorization in browser, then return here'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Apps'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Connect your fitness and calendar apps to unlock personalized features',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          _IntegrationCard(
            title: 'Strava',
            description: 'Sync your running, cycling, and workout activities',
            icon: Icons.directions_run,
            iconColor: const Color(0xFFFC4C02),
            connected: _stravaConnected,
            onConnect: _connectStrava,
            onDisconnect: () {/* TODO */},
          ),
          
          const SizedBox(height: 16),
          
          _IntegrationCard(
            title: 'Google Calendar',
            description: 'Add events to your calendar with one tap',
            icon: Icons.calendar_today,
            iconColor: const Color(0xFF4285F4),
            connected: _calendarConnected,
            onConnect: _connectCalendar,
            onDisconnect: () {/* TODO */},
          ),
          
          // Add more integrations here
        ],
      ),
    );
  }
  
  String getCurrentUserId() {
    // TODO: Get from Supabase auth
    return 'user_123';
  }
}

class _IntegrationCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool connected;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _IntegrationCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.connected,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            connected
                ? Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onDisconnect,
                        child: const Text('Disconnect'),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: onConnect,
                    child: const Text('Connect'),
                  ),
          ],
        ),
      ),
    );
  }
}
```

#### 4.2 Event Detail - Add to Calendar Button

**File:** `lib/screens/discover/event_detail_screen.dart` (enhance existing)

```dart
// Add this to your existing event detail screen

class EventDetailScreen extends StatelessWidget {
  final EventModel event;
  final _calendarIntegration = CalendarIntegration();

  // ... existing code ...

  Widget _buildAddToCalendarButton(BuildContext context) {
    return FutureBuilder<bool>(
      future: _calendarIntegration.isConnected(getCurrentUserId()),
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;
        
        return ElevatedButton.icon(
          onPressed: isConnected
              ? () => _addToCalendar(context)
              : () => _promptConnect(context),
          icon: const Icon(Icons.calendar_today),
          label: Text(isConnected ? 'Add to Calendar' : 'Connect Calendar'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        );
      },
    );
  }

  Future<void> _addToCalendar(BuildContext context) async {
    // Check availability first
    final available = await _calendarIntegration.checkAvailability(
      userId: getCurrentUserId(),
      start: event.start,
      end: event.end ?? event.start.add(const Duration(hours: 2)),
    );

    if (!available) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Calendar Conflict'),
          content: const Text(
            'You have another event at this time. Add anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add Anyway'),
            ),
          ],
        ),
      );
      
      if (proceed != true) return;
    }

    // Add to calendar
    final result = await _calendarIntegration.addEventToCalendar(
      userId: getCurrentUserId(),
      event: event,
    );

    if (result.success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Event added to your calendar'),
          action: result.htmlLink != null
              ? SnackBarAction(
                  label: 'View',
                  onPressed: () => launchUrl(Uri.parse(result.htmlLink!)),
                )
              : null,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to add event: ${result.error}'),
        ),
      );
    }
  }

  void _promptConnect(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect Google Calendar'),
        content: const Text(
          'Connect your Google Calendar to add events with one tap.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const IntegrationsScreen(),
                ),
              );
            },
            child: const Text('Connect Now'),
          ),
        ],
      ),
    );
  }
}
```

---

### Phase 5: Background Sync (Week 5-6)

#### 5.1 Sync Service

**File:** `lib/services/sync_service.dart`

```dart
import 'package:workmanager/workmanager.dart';
import 'package:fittravel/composio/integrations/strava_integration.dart';

class SyncService {
  static const String syncTaskName = 'composio_sync';
  
  /// Initialize background sync
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Schedule periodic sync
  static Future<void> scheduleSyncTask(String userId) async {
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(hours: 6), // Sync every 6 hours
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      inputData: {
        'userId': userId,
      },
    );
  }

  /// Cancel sync task
  static Future<void> cancelSyncTask() async {
    await Workmanager().cancelByUniqueName(syncTaskName);
  }

  /// Manual sync
  static Future<SyncResult> syncNow(String userId) async {
    final stravaIntegration = StravaIntegration();
    
    try {
      final isConnected = await stravaIntegration.isConnected(userId);
      if (!isConnected) {
        return SyncResult(success: false, message: 'Not connected');
      }

      final count = await stravaIntegration.syncActivities(userId);
      
      return SyncResult(
        success: true,
        message: 'Synced $count activities',
        activitiesSynced: count,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
      );
    }
  }
}

/// Background task callback
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == SyncService.syncTaskName) {
      final userId = inputData?['userId'] as String?;
      if (userId != null) {
        await SyncService.syncNow(userId);
      }
    }
    return Future.value(true);
  });
}

class SyncResult {
  final bool success;
  final String message;
  final int? activitiesSynced;

  SyncResult({
    required this.success,
    required this.message,
    this.activitiesSynced,
  });
}
```

---

## 🧪 Testing Strategy

### Unit Tests

**File:** `test/composio/composio_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fittravel/composio/composio_service.dart';

void main() {
  group('ComposioService', () {
    late ComposioService service;

    setUp(() {
      service = ComposioService();
    });

    test('generates correct entity ID', () {
      final entityId = service.getEntityId('user_123');
      expect(entityId, equals('lumofit_user_123'));
    });

    // Add more tests
  });
}
```

### Integration Tests

**File:** `integration_test/strava_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fittravel/composio/integrations/strava_integration.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Strava Integration E2E', () {
    testWidgets('Connect and fetch activities', (tester) async {
      final integration = StravaIntegration();
      final testUserId = 'test_user_123';

      // Test connection
      final result = await integration.connect(testUserId);
      expect(result.success, isTrue);
      expect(result.redirectUrl, isNotNull);

      // Note: Actual OAuth flow requires manual user interaction
      // This test documents the expected flow
    });
  });
}
```

---

## 💰 Cost Estimation

### Composio Pricing (Estimated)

Based on typical usage patterns:

| User Activity | Actions/Month/User | Cost per Action | Monthly Cost/User |
|---------------|-------------------|-----------------|-------------------|
| Strava Sync (2x/day) | 60 | $0.01 | $0.60 |
| Calendar Events (5 events) | 5 | $0.01 | $0.05 |
| Profile Checks | 10 | $0.005 | $0.05 |
| **Total per User** | **~75** | - | **~$0.70** |

### Monthly Cost Projections

| Active Users | Monthly Cost | Annual Cost |
|-------------|--------------|-------------|
| 100 | $70 | $840 |
| 500 | $350 | $4,200 |
| 1,000 | $700 | $8,400 |
| 5,000 | $3,500 | $42,000 |
| 10,000 | $7,000 | $84,000 |

### Cost Optimization Strategies

1. **Cache aggressively**: Store synced data locally, reduce API calls
2. **Batch operations**: Group multiple actions in single requests
3. **Smart sync intervals**: Sync less frequently for inactive users
4. **Use webhooks**: Instead of polling (when available)
5. **Tiered features**: Premium users get more frequent syncs

---

## 📅 Implementation Timeline

### Week 1-2: Foundation
- ✅ Set up Composio SDK
- ✅ Implement ComposioService
- ✅ Entity management
- ✅ Secure storage for tokens

### Week 3-4: Core Integrations
- ✅ Strava integration
- ✅ Google Calendar integration
- ✅ Activity model enhancements
- ✅ UI for connections

### Week 5-6: Polish & Testing
- ✅ Background sync service
- ✅ Error handling & retry logic
- ✅ Unit tests
- ✅ Integration tests
- ✅ User documentation

### Week 7+: Launch & Iterate
- 📊 Monitor usage & costs
- 🐛 Fix bugs
- 🎯 Add more integrations (Apple Health, Garmin)

---

## 🚀 Deployment Checklist

### Pre-Launch

- [ ] **Environment Variables**
  - [ ] Set `COMPOSIO_API_KEY` in production
  - [ ] Configure redirect URLs in Composio dashboard
  - [ ] Update OAuth callback URLs in app config

- [ ] **App Store Setup**
  - [ ] Add OAuth redirect scheme to iOS `Info.plist`
  - [ ] Add OAuth redirect to Android `AndroidManifest.xml`
  - [ ] Update privacy policy (data usage disclosure)
  - [ ] App Store Connect: Add Strava/Calendar screenshots

- [ ] **Testing**
  - [ ] Test OAuth flows on iOS
  - [ ] Test OAuth flows on Android
  - [ ] Test sync reliability
  - [ ] Test error scenarios (no connection, expired tokens)

- [ ] **Documentation**
  - [ ] User guide: How to connect apps
  - [ ] FAQ: Common connection issues
  - [ ] Support documentation

### Post-Launch

- [ ] **Monitoring**
  - [ ] Set up Composio usage alerts
  - [ ] Monitor sync success rates
  - [ ] Track connection churn
  - [ ] User feedback collection

- [ ] **Optimization**
  - [ ] Analyze most expensive operations
  - [ ] Implement caching strategies
  - [ ] A/B test sync frequencies

---

## 🔐 Security Considerations

### Data Protection

1. **Token Storage**: Use `flutter_secure_storage` for OAuth tokens
2. **Entity IDs**: Never expose raw user IDs, use prefixed entities
3. **API Keys**: Store Composio API key securely, never commit to git
4. **Data Minimization**: Only request necessary scopes from users

### Privacy Compliance

1. **GDPR**: Implement data deletion on user request
2. **Privacy Policy**: Update to include third-party data processing
3. **Consent**: Clear opt-in for each integration
4. **Data Retention**: Define and enforce retention policies

---

## 📚 Resources & Links

### Documentation
- [Composio SDK Docs](https://docs.composio.dev)
- [Composio Flutter SDK](https://pub.dev/packages/composio_flutter)
- [Strava API Docs](https://developers.strava.com)
- [Google Calendar API](https://developers.google.com/calendar/api)

### Support
- Composio Discord: [Join Community](https://discord.gg/composio)
- GitHub Issues: [composiohq/composio](https://github.com/composiohq/composio)

---

## 🎯 Success Metrics

### KPIs to Track

1. **Adoption Rate**
   - % of users who connect at least one app
   - Target: 40% within 3 months

2. **Engagement**
   - Activities synced per user per month
   - Calendar events added per user per month

3. **Retention**
   - Users still connected after 30/60/90 days
   - Target: 80% retention at 30 days

4. **Technical**
   - Sync success rate: >95%
   - Connection failure rate: <5%
   - Average sync latency: <10 seconds

5. **Business**
   - Cost per active user: <$1/month
   - Revenue impact (if premium feature)

---

## 📝 Next Steps

1. **Review this plan** with your team
2. **Set up Composio account** at [app.composio.dev](https://app.composio.dev)
3. **Create test environment** for development
4. **Start with Phase 1** (Foundation)
5. **Schedule weekly progress reviews**

---

## 🤝 Questions?

If you have questions about this implementation plan:
- Open a GitHub issue
- Tag `@composio` for SDK-specific questions
- Reach out to the Composio team via Discord

---

**Document Version:** 1.0  
**Last Updated:** January 20, 2026  
**Maintained By:** LumoFit Development Team

---

*This plan is a living document. Update it as you make progress!* 🚀
