import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fittravel/services/services.dart';
import 'package:fittravel/theme.dart';

/// Creates a testable widget wrapped with necessary providers and theme
Widget createTestApp({
  required Widget child,
  UserService? userService,
  TripService? tripService,
  PlaceService? placeService,
  ActivityService? activityService,
  GamificationService? gamificationService,
}) {
  return MultiProvider(
    providers: [
      if (userService != null)
        ChangeNotifierProvider<UserService>.value(value: userService),
      if (tripService != null)
        ChangeNotifierProvider<TripService>.value(value: tripService),
      if (placeService != null)
        ChangeNotifierProvider<PlaceService>.value(value: placeService),
      if (activityService != null)
        ChangeNotifierProvider<ActivityService>.value(value: activityService),
      if (gamificationService != null)
        ChangeNotifierProvider<GamificationService>.value(
            value: gamificationService),
    ],
    child: MaterialApp(
      theme: appTheme,
      home: child,
    ),
  );
}

/// Pumps a widget with default test app wrapper
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget child, {
  UserService? userService,
  TripService? tripService,
  PlaceService? placeService,
  ActivityService? activityService,
  GamificationService? gamificationService,
}) async {
  await tester.pumpWidget(
    createTestApp(
      child: child,
      userService: userService,
      tripService: tripService,
      placeService: placeService,
      activityService: activityService,
      gamificationService: gamificationService,
    ),
  );
}
