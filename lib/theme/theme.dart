import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'text_styles.dart';

ThemeData buildKaTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: KaColors.surface,
    colorScheme: const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: KaColors.primary,
      onPrimary: KaColors.onPrimary,
      primaryContainer: KaColors.primaryContainer,
      secondary: KaColors.tertiary,
      onSecondary: KaColors.onPrimary,
      error: KaColors.error,
      onError: KaColors.onError,
      surface: KaColors.surface,
      onSurface: KaColors.onSurface,
      surfaceContainerLowest: KaColors.surfaceContainerLowest,
      surfaceContainerLow: KaColors.surfaceContainerLow,
      surfaceContainer: KaColors.surfaceContainer,
      surfaceContainerHigh: KaColors.surfaceContainerHigh,
      surfaceContainerHighest: KaColors.surfaceContainerHighest,
      outline: KaColors.outlineVariant,
      outlineVariant: KaColors.outlineVariant,
    ),
    textTheme: TextTheme(
      displayLarge: KaTextStyles.displayLarge,
      displayMedium: KaTextStyles.displayMedium,
      displaySmall: KaTextStyles.displaySmall,
      headlineLarge: KaTextStyles.headlineLarge,
      headlineMedium: KaTextStyles.headlineMedium,
      headlineSmall: KaTextStyles.headlineSmall,
      titleLarge: KaTextStyles.titleLarge,
      titleMedium: KaTextStyles.titleMedium,
      titleSmall: KaTextStyles.titleSmall,
      bodyLarge: KaTextStyles.bodyLarge,
      bodyMedium: KaTextStyles.bodyMedium,
      bodySmall: KaTextStyles.bodySmall,
      labelLarge: KaTextStyles.labelLarge,
      labelMedium: KaTextStyles.labelMedium,
      labelSmall: KaTextStyles.labelSmall,
    ),
    // No borders — tonal separation only
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KaColors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: KaColors.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: KaTextStyles.bodyMedium.copyWith(color: KaColors.onSurfaceVariant),
      labelStyle: KaTextStyles.labelLarge.copyWith(color: KaColors.onSurfaceVariant),
    ),
    // Navigation bar
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: KaColors.surfaceContainerLow,
      indicatorColor: KaColors.primary.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: KaColors.primary, size: 24);
        }
        return const IconThemeData(color: KaColors.onSurfaceVariant, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: KaColors.primary,
          );
        }
        return GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: KaColors.onSurfaceVariant,
        );
      }),
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    // Cards — no shadows, tonal layering only
    cardTheme: CardThemeData(
      color: KaColors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    // Switches — cyan thumb
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return KaColors.primary;
        return KaColors.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return KaColors.primary.withValues(alpha: 0.3);
        }
        return KaColors.surfaceContainerHighest;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    // Dividers banned — use spacing instead
    dividerTheme: const DividerThemeData(color: Colors.transparent, space: 0),
    appBarTheme: AppBarTheme(
      backgroundColor: KaColors.surfaceContainerLow,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: KaTextStyles.titleLarge,
      iconTheme: const IconThemeData(color: KaColors.onSurface),
    ),
  );
}
