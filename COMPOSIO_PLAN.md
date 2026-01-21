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
│  ┌────────────────────────────────────────────────┐    │
│  │   USER-SPECIFIC (Composio SDK)             │    │
│  │                                            │    │
│  │  ✅ Strava - Activity sync                 │    │
│  │  ✅ Google Calendar - Event management     │    │
│  │  ✅ Apple Health - Health data sync        │    │
│  │  ✅ Google Fit - Android fitness tracking  │    │
│  │  ✅ Garmin - Device sync (future)          │    │
│  │                                            │    │
│  └────────────────────────────────────────────────┘    │
│                                                      │
│  ┌────────────────────────────────────────────────┐    │
│  │   GLOBAL/SHARED (Keep Existing)            │    │
│  │                                            │    │
│  │  📍 Event Search (Eventbrite, RunSignup)   │    │
│  │  🗺️  Google Maps (Public places)           │    │
│  │  ☁️  Weather API                            │    │
│  │                                            │    │
│  └────────────────────────────────────────────────┘    │
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

---

### Phase 2: Strava Integration (Week 2-3)

See full code examples in sections 2.1-2.2 of the complete plan.

Key features:
- Activity sync (runs, rides, workouts)
- Athlete profile fetching
- Background sync every 6 hours
- Local caching for offline access

---

### Phase 3: Google Calendar Integration (Week 3-4)

See full code examples in section 3.1 of the complete plan.

Key features:
- Add events to user's calendar
- Check availability before adding
- Smart conflict detection
- Calendar event links

---

### Phase 4: UI Implementation (Week 4-5)

Key screens:
- **Integrations Screen**: Connect/disconnect apps
- **Activity History**: View synced workouts
- **Event Detail**: Add to calendar button
- **Profile Settings**: Manage connections

---

### Phase 5: Background Sync (Week 5-6)

Implement:
- Periodic background sync (every 6 hours)
- Manual sync trigger
- Sync status indicators
- Error handling & retries

---

## 💰 Cost Estimation

### Composio Pricing (Estimated)

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
