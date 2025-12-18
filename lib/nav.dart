import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:fittravel/screens/main_shell.dart';
import 'package:fittravel/screens/home/home_screen.dart';
import 'package:fittravel/screens/discover/discover_screen.dart';
import 'package:fittravel/screens/discover/place_detail_screen.dart';
import 'package:fittravel/screens/trips/trips_screen.dart';
import 'package:fittravel/screens/profile/profile_screen.dart';
import 'package:fittravel/screens/trips/trip_detail_screen.dart';
import 'package:fittravel/models/place_model.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/screens/discover/event_detail_screen.dart';
import 'package:fittravel/screens/auth/login_screen.dart';
import 'package:fittravel/screens/auth/signup_screen.dart';
import 'package:fittravel/screens/auth/forgot_password_screen.dart';
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:fittravel/screens/feedback/feedback_screen.dart';
import 'package:fittravel/screens/home/cairo_guide_screen.dart';
import 'package:fittravel/screens/map/map_screen.dart';
import 'package:fittravel/screens/trips/itinerary_generator_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();
  static final _refreshListenable =
      GoRouterRefreshStream(SupabaseConfig.auth.onAuthStateChange);

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: _refreshListenable,
    redirect: (context, state) {
      final isLoggedIn = SupabaseConfig.auth.currentUser != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup') ||
          state.matchedLocation.startsWith('/forgot-password');

      // If not logged in and not on auth route, redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // If logged in and on auth route, redirect to home
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (context, state) {
              final filter = state.uri.queryParameters['filter'];
              return NoTransitionPage(
                child: MapScreen(initialFilter: filter),
              );
            },
          ),
          GoRoute(
            path: '/discover',
            pageBuilder: (context, state) {
              final tab = state.uri.queryParameters['tab'];
              int initialIndex = 0;
              switch (tab) {
                case 'gyms':
                  initialIndex = 0;
                  break;
                case 'food':
                  initialIndex = 1;
                  break;
                case 'events':
                  initialIndex = 2;
                  break;
                case 'trails':
                  initialIndex = 3;
                  break;
                case 'saved':
                  initialIndex = 4;
                  break;
                default:
                  initialIndex = 0;
              }
              return NoTransitionPage(
                child: DiscoverScreen(initialTabIndex: initialIndex),
              );
            },
          ),
          GoRoute(
            path: '/trips',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TripsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      // Full screen routes (outside shell)
      GoRoute(
        path: '/place-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final place = state.extra as PlaceModel;
          return PlaceDetailScreen(place: place);
        },
      ),
      GoRoute(
        path: '/trip/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TripDetailScreen(tripId: id);
        },
      ),
      GoRoute(
        path: '/event-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final event = state.extra as EventModel;
          return EventDetailScreen(event: event);
        },
      ),
      GoRoute(
        path: '/cairo-guide',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CairoGuideScreen(),
      ),
      GoRoute(
        path: '/feedback',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/generate-itinerary',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final destination = state.uri.queryParameters['destination'];
          return ItineraryGeneratorScreen(initialDestination: destination);
        },
      ),
      // Auth routes
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
    ],
  );

  static int getCurrentIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/discover')) return 2;
    if (location.startsWith('/trips')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  static String getPathForIndex(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/map';
      case 2:
        return '/discover';
      case 3:
        return '/trips';
      case 4:
        return '/profile';
      default:
        return '/home';
    }
  }
}

/// A simple ChangeNotifier that triggers GoRouter to refresh when the provided
/// stream emits an event. This lets us react to Supabase auth state changes
/// (login/logout) and run redirect logic automatically.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
