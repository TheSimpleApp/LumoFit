import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/nav.dart';
import 'package:fittravel/services/services.dart';
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:fittravel/config/app_config.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

void main() async {
  MarionetteBinding.ensureInitialized(const MarionetteConfiguration());

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

  // Initialize app with error handling
  try {
    // Validate app configuration (API keys, etc.)
    AppConfig.validate();

    // Initialize Supabase
    await SupabaseConfig.initialize();

    // Important: runApp in the same zone where bindings were initialized.
    runApp(const MyApp());
  } catch (e, stackTrace) {
    // If initialization fails, show error screen instead of white screen
    debugPrint('❌ App initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(ErrorApp(error: e.toString(), stackTrace: stackTrace.toString()));
  }
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
        ChangeNotifierProvider(
          create: (_) => StravaService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => MapContextService(),
        ),
        Provider(
          create: (_) => AiGuideService(),
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

/// Error screen shown when app initialization fails
class ErrorApp extends StatelessWidget {
  final String error;
  final String stackTrace;

  const ErrorApp({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LumoFit',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      darkTheme: appTheme,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Initialization Error',
                  style: AppTypography.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'The app failed to initialize. Please try restarting the app.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (kDebugMode) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error Details (Debug Only):',
                          style: AppTypography.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
