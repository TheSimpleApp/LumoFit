import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fittravel/screens/main_shell.dart';
import 'package:fittravel/screens/home/home_screen.dart';
import 'package:fittravel/screens/discover/discover_screen.dart';
import 'package:fittravel/screens/discover/place_detail_screen.dart';
import 'package:fittravel/screens/trips/trips_screen.dart';
import 'package:fittravel/screens/profile/profile_screen.dart';
import 'package:fittravel/screens/trips/trip_detail_screen.dart';
import 'package:fittravel/models/place_model.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
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
                case 'saved':
                  initialIndex = 2;
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
    ],
  );

  static int getCurrentIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/discover')) return 1;
    if (location.startsWith('/trips')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  static String getPathForIndex(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/discover';
      case 2:
        return '/trips';
      case 3:
        return '/profile';
      default:
        return '/home';
    }
  }
}
