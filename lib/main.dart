import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/nav.dart';
import 'package:fittravel/services/services.dart';
import 'package:fittravel/supabase/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  // Initialize storage service
  final storage = await StorageService.getInstance();

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
    runApp(MyApp(storage: storage));
  }, (Object error, StackTrace stack) {
    debugPrint('[ZoneError] $error');
    debugPrint(stack.toString());
  });
}

class MyApp extends StatelessWidget {
  final StorageService storage;
  
  const MyApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserService(storage)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => PlaceService(storage)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => TripService(storage)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => ActivityService(storage)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => GamificationService(storage)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => CommunityPhotoService(storage)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => QuickPhotoService(storage)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewService(storage)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => EventService(storage)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => FeedbackService(storage)..initialize(),
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
