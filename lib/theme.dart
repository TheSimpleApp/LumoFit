import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =============================================================================
// FITTRAVEL PREMIUM EXECUTIVE THEME
// Design: Black background, classic gold accent, executive luxury
// Target: High-level executives, entrepreneurs, business travelers
// Inspired by: Amex Gold, Four Seasons, executive timepieces
// =============================================================================

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
}

class AppRadius {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double full = 999.0;
}

// =============================================================================
// CORE COLOR PALETTE - Premium Executive
// =============================================================================

class AppColors {
  // -------------------------------------------------------------------------
  // Backgrounds - Pure black foundation
  // -------------------------------------------------------------------------
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF242424);
  static const Color surfaceBorder = Color(0xFF2A2A2A);
  // Premium surface additions
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color surfaceGlass = Color(0xCC151515); // 80% opacity

  // -------------------------------------------------------------------------
  // Primary Accent - Classic Gold (executive, sophisticated)
  // -------------------------------------------------------------------------
  static const Color primary = Color(0xFFD4AF37); // Classic gold
  static const Color primaryMuted = Color(0x26D4AF37); // 15% opacity
  static const Color primaryDim = Color(0x4DD4AF37); // 30% opacity
  // Premium gold variations
  static const Color goldLight = Color(0xFFF5D76E); // Highlights, shimmer peaks
  static const Color goldDark = Color(0xFFB8860B); // Shadows, depth
  static const Color goldGlow = Color(0x80D4AF37); // 50% for glow effects
  static const Color borderGold = Color(0x33D4AF37); // 20% for subtle borders
  static const Color champagne = Color(0xFFF7E7CE); // Premium text highlights

  // -------------------------------------------------------------------------
  // Category Colors - Premium palette for map pins & UI accents
  // Carefully selected to complement gold and feel sophisticated
  // -------------------------------------------------------------------------
  static const Color categoryGym = Color(0xFF3B82F6); // Sapphire Blue
  static const Color categoryGymMuted = Color(0x263B82F6);
  static const Color categoryFood = Color(0xFFF97316); // Warm Coral
  static const Color categoryFoodMuted = Color(0x26F97316);
  static const Color categoryTrail = Color(0xFF10B981); // Emerald Green
  static const Color categoryTrailMuted = Color(0x2610B981);
  static const Color categoryEvent = Color(0xFF8B5CF6); // Royal Purple
  static const Color categoryEventMuted = Color(0x268B5CF6);

  // Marker hue values for Google Maps (HSL hue 0-360)
  // These correspond to the category colors above
  static const double markerHueGym = 217.0; // Sapphire Blue
  static const double markerHueFood = 25.0; // Warm Coral
  static const double markerHueTrail = 160.0; // Emerald Green
  static const double markerHueEvent = 258.0; // Royal Purple
  static const double markerHueSaved = 45.0; // Gold (saved places)

  // -------------------------------------------------------------------------
  // Neutral - Gray scale
  // -------------------------------------------------------------------------
  static const Color inactive = Color(0xFF3A3A3A);
  static const Color muted = Color(0xFF4A4A4A);
  static const Color subtle = Color(0xFF5A5A5A);

  // -------------------------------------------------------------------------
  // Text hierarchy
  // -------------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textTertiary = Color(0xFF6A6A6A);
  static const Color textMuted = Color(0xFF4A4A4A);

  // -------------------------------------------------------------------------
  // Semantic - Keep minimal and muted
  // -------------------------------------------------------------------------
  static const Color success = Color(0xFF4ADE80);
  static const Color successMuted = Color(0x264ADE80);
  static const Color error = Color(0xFFEF4444);
  static const Color errorMuted = Color(0x26EF4444);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningMuted = Color(0x26FBBF24);
  static const Color info = Color(0xFF60A5FA);
  static const Color infoMuted = Color(0x2660A5FA);

  // -------------------------------------------------------------------------
  // XP/Gamification - All gold-based for consistency
  // -------------------------------------------------------------------------
  static const Color xp = primary;
  static const Color xpMuted = primaryMuted;
  static const Color badge = primary;
  static const Color level = primary;

  // -------------------------------------------------------------------------
  // Gradients - Premium (use sparingly)
  // -------------------------------------------------------------------------

  /// Rich gold gradient for premium buttons and headers
  static const LinearGradient goldPremium = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Shimmer effect for badges and highlights
  static const LinearGradient goldShimmer = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFF5D76E), Color(0xFFD4AF37)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle surface gradient for premium cards
  static const LinearGradient surfacePremium = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF151515)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Radial gold glow for focused elements
  static RadialGradient goldRadialGlow(double radius) => RadialGradient(
        colors: [goldGlow, Colors.transparent],
        radius: radius,
      );
}

// =============================================================================
// TYPOGRAPHY
// =============================================================================

class AppTypography {
  // Broad glyph coverage fallback list to reduce missing Noto font warnings on web
  static const List<String> _fallback = <String>[
    'Noto Sans',
    'Noto Color Emoji',
    'Noto Sans Symbols 2',
  ];
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1.1,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.2,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get displaySmall => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.2,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.3,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get headlineSmall => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textTertiary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.2,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.2,
        color: AppColors.textSecondary,
      ).copyWith(fontFamilyFallback: _fallback);

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.2,
        color: AppColors.textTertiary,
      ).copyWith(fontFamilyFallback: _fallback);
}

// =============================================================================
// EXTENSIONS
// =============================================================================

extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);

  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
  TextStyle withHeight(double height) => copyWith(height: height);

  // Premium gold text styles
  TextStyle get gold => copyWith(color: AppColors.primary);
  TextStyle get goldLight => copyWith(color: AppColors.goldLight);
  TextStyle get champagne => copyWith(color: AppColors.champagne);

  // Category color text styles
  TextStyle get gym => copyWith(color: AppColors.categoryGym);
  TextStyle get food => copyWith(color: AppColors.categoryFood);
  TextStyle get trail => copyWith(color: AppColors.categoryTrail);
  TextStyle get event => copyWith(color: AppColors.categoryEvent);
}

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
}

// =============================================================================
// THEME DATA - Dark Only
// =============================================================================

ThemeData get appTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Color(0xFF000000),
        primaryContainer: AppColors.primaryMuted,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.textSecondary,
        onSecondary: AppColors.background,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceLight,
        onSurfaceVariant: AppColors.textSecondary,
        error: AppColors.error,
        onError: AppColors.textPrimary,
        outline: AppColors.surfaceBorder,
        shadow: Colors.black,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // AppBar - Transparent, minimal
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge,
      ),

      // Cards - Subtle border, no shadow
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Primary Button - Gold background
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppColors.inactive,
          disabledForegroundColor: AppColors.textTertiary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ).copyWith(fontFamilyFallback: AppTypography._fallback),
        ),
      ),

      // Secondary Button - Outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textTertiary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ).copyWith(fontFamilyFallback: AppTypography._fallback),
        ),
      ),

      // Text Button - Minimal
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ).copyWith(fontFamilyFallback: AppTypography._fallback),
        ),
      ),

      // FAB - Gold accent
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: CircleBorder(),
      ),

      // Bottom Navigation - Clean
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.inactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ).copyWith(fontFamilyFallback: AppTypography._fallback),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ).copyWith(fontFamilyFallback: AppTypography._fallback),
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryMuted,
        elevation: 0,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.inactive, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ).copyWith(fontFamilyFallback: AppTypography._fallback);
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.inactive,
          ).copyWith(fontFamilyFallback: AppTypography._fallback);
        }),
      ),

      // Input - Subtle with border
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: GoogleFonts.inter(
          color: AppColors.textTertiary,
          fontSize: 16,
        ).copyWith(fontFamilyFallback: AppTypography._fallback),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ).copyWith(fontFamilyFallback: AppTypography._fallback),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide:
              const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide:
              const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.inactive, width: 1),
        ),
      ),

      // Chips - Pill shaped
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryMuted,
        disabledColor: AppColors.inactive,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ).copyWith(fontFamilyFallback: AppTypography._fallback),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ).copyWith(fontFamilyFallback: AppTypography._fallback),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 1,
        space: 1,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.headlineMedium,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: AppColors.inactive,
        dragHandleSize: Size(36, 4),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 14,
        ).copyWith(fontFamilyFallback: AppTypography._fallback),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryMuted;
          }
          return AppColors.inactive;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: const BorderSide(color: AppColors.surfaceBorder, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.surfaceBorder;
        }),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.inactive,
        circularTrackColor: AppColors.inactive,
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.inactive,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primaryMuted,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
    );

// =============================================================================
// COMPONENT HELPERS (for custom widgets)
// =============================================================================

class AppDecorations {
  // -------------------------------------------------------------------------
  // Standard Decorations
  // -------------------------------------------------------------------------

  /// Standard card decoration with border
  static BoxDecoration get card => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      );

  /// Elevated card (subtle elevation feel via lighter bg)
  static BoxDecoration get cardElevated => BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      );

  /// XP/Badge container - gold accent
  static BoxDecoration get badge => BoxDecoration(
        color: AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3), width: 1),
      );

  /// Selected/active state
  static BoxDecoration get selected => BoxDecoration(
        color: AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary, width: 1),
      );

  /// Input field style
  static BoxDecoration get input => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      );

  // -------------------------------------------------------------------------
  // Premium Decorations
  // -------------------------------------------------------------------------

  /// Premium card with subtle gold border accent
  static BoxDecoration get cardPremium => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderGold, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Glass-morphism card with gold tint
  static BoxDecoration get cardGlass => BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderGold, width: 1),
      );

  /// Premium badge with gold shimmer gradient
  static BoxDecoration get badgePremium => BoxDecoration(
        gradient: AppColors.goldShimmer,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Selected state with gold glow
  static BoxDecoration get selectedPremium => BoxDecoration(
        color: AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      );

  /// Premium button with gradient background
  static BoxDecoration get buttonPremium => BoxDecoration(
        gradient: AppColors.goldPremium,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldDark.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // -------------------------------------------------------------------------
  // Category Decorations (for chips, badges, map markers)
  // -------------------------------------------------------------------------

  static BoxDecoration categoryChip(Color color, Color mutedColor) =>
      BoxDecoration(
        color: mutedColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      );

  static BoxDecoration get gymChip =>
      categoryChip(AppColors.categoryGym, AppColors.categoryGymMuted);

  static BoxDecoration get foodChip =>
      categoryChip(AppColors.categoryFood, AppColors.categoryFoodMuted);

  static BoxDecoration get trailChip =>
      categoryChip(AppColors.categoryTrail, AppColors.categoryTrailMuted);

  static BoxDecoration get eventChip =>
      categoryChip(AppColors.categoryEvent, AppColors.categoryEventMuted);
}
