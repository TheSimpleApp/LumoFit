import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/nav.dart';
import 'package:fittravel/services/services.dart';
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:fittravel/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate app configuration (API keys, etc.)
  AppConfig.validate();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Global error handling to reduce noisy preview logs and capture unexpected errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Keep default Flutter behavior
    FlutterError.presentError(details);
    // Log to console for Dreamflow Debug Console
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint(details.stack.toString());
    }
  };

  // Handle errors outside Flutter framework (e.g., platform/async zones)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[PlatformError] $error');
    debugPrint(stack.toString());
    return true; // mark as handled to avoid duplicate noisy logs
  };

  runZonedGuarded(() {
    runApp(const MyApp());
  }, (Object error, StackTrace stack) {
    debugPrint('[ZoneError] $error');
    debugPrint(stack.toString());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => PlaceService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => TripService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => ActivityService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => GamificationService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => CommunityPhotoService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => QuickPhotoService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => EventService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => FeedbackService()..initialize(),
        ),
      ],
      child: MaterialApp.router(
        title: 'LumoFit',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        darkTheme: appTheme,
        themeMode: ThemeMode.dark,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
