import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom theme extension for app-specific colors not in ColorScheme.
class AppColors extends ThemeExtension<AppColors> {
  final Color gradientStart;
  final Color gradientEnd;
  final Color success;
  final Color warning;
  final Color accent;
  final Color surface;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color online;
  final Color offline;

  const AppColors({
    required this.gradientStart,
    required this.gradientEnd,
    required this.success,
    required this.warning,
    required this.accent,
    required this.surface,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.online,
    required this.offline,
  });

  @override
  AppColors copyWith({
    Color? gradientStart,
    Color? gradientEnd,
    Color? success,
    Color? warning,
    Color? accent,
    Color? surface,
    Color? card,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? online,
    Color? offline,
  }) {
    return AppColors(
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      accent: accent ?? this.accent,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      online: online ?? this.online,
      offline: offline ?? this.offline,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      online: Color.lerp(online, other.online, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  // ── Ocean Blue Brand Palette ──────────────────────────────────────────
  static const Color primary = Color(0xFF2D6CDF);
  static const Color primaryColor = primary; // backward compat alias
  static const Color primaryDark = Color(0xFF1E56B8);
  static const Color secondary = Color(0xFFFF6B35);
  static const Color accent = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFEF4444);
  static const Color surface = Color(0xFFF7F8FC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Status colors
  static const Color onlineColor = Color(0xFF10B981);
  static const Color offlineColor = Color(0xFF9CA3AF);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);

  // Gradients
  static const Color gradientStart = Color(0xFF2D6CDF);
  static const Color gradientEnd = Color(0xFF60A5FA);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  // ── Spacing (4px grid) ────────────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingBase = 16;
  static const double spacingLg = 20;
  static const double spacingXl = 24;
  static const double spacing2xl = 32;
  static const double spacing3xl = 40;
  static const double spacing4xl = 48;

  // ── Border Radius ─────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  // ── Shadows ───────────────────────────────────────────────────────────
  static List<BoxShadow> get shadowNone => [];

  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          offset: const Offset(0, 1),
          blurRadius: 2,
          color: Colors.black.withValues(alpha: 0.04),
        ),
        BoxShadow(
          offset: const Offset(0, 1),
          blurRadius: 3,
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          offset: const Offset(0, 2),
          blurRadius: 4,
          color: Colors.black.withValues(alpha: 0.04),
        ),
        BoxShadow(
          offset: const Offset(0, 4),
          blurRadius: 8,
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          offset: const Offset(0, 4),
          blurRadius: 6,
          color: Colors.black.withValues(alpha: 0.04),
        ),
        BoxShadow(
          offset: const Offset(0, 10),
          blurRadius: 20,
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ];

  // ── Custom AppColors Extension ────────────────────────────────────────
  static const AppColors appColors = AppColors(
    gradientStart: gradientStart,
    gradientEnd: gradientEnd,
    success: successColor,
    warning: warningColor,
    accent: accent,
    surface: surface,
    card: card,
    border: border,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textTertiary: textTertiary,
    online: onlineColor,
    offline: offlineColor,
  );

  // ── Typography ────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme() {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: textPrimary,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: textPrimary,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: textPrimary,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textPrimary,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textPrimary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: textPrimary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textPrimary,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textSecondary,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textSecondary,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textPrimary,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: textSecondary,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: textTertiary,
      ),
    );
  }

  // ── Theme Data ────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFDBEAFE),
        secondary: secondary,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        outline: border,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,

      // ── App Bar ─────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: textTheme.titleLarge,
      ),

      // ── Card ────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // ── Input Decoration ────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingBase,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textTertiary),
        labelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Elevated Button ─────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── FAB ─────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),

      // ── Chip ────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.12),
        labelStyle: textTheme.labelMedium!,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: const BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── Tab Bar ─────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.bodyMedium,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // ── Bottom Nav ──────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        showUnselectedLabels: true,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),

      // ── Snack Bar ───────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        backgroundColor: textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),

      // ── Divider ─────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // ── Dialog ──────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
      ),

      // ── Bottom Sheet ────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXl),
          ),
        ),
      ),

      // ── Extensions ──────────────────────────────────────────────────
      extensions: const [appColors],
    );
  }
}
