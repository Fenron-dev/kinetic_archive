import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Typography — Manrope for Display/Headline, Inter for Body/Label/UI.
abstract final class KaTextStyles {
  // ---------- Display (Manrope) ----------
  // For storage capacities, critical status numbers
  static TextStyle displayLarge = GoogleFonts.manrope(
    fontSize: 57,
    fontWeight: FontWeight.w800,
    color: KaColors.onSurface,
    letterSpacing: -0.25,
  );

  static TextStyle displayMedium = GoogleFonts.manrope(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    color: KaColors.onSurface,
  );

  static TextStyle displaySmall = GoogleFonts.manrope(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: KaColors.onSurface,
  );

  // ---------- Headline (Manrope) ----------
  // Section titles — creates clear entry point for the eye
  static TextStyle headlineLarge = GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: KaColors.onSurface,
  );

  static TextStyle headlineMedium = GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: KaColors.onSurface,
  );

  static TextStyle headlineSmall = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: KaColors.onSurface,
  );

  // ---------- Title (Manrope) ----------
  static TextStyle titleLarge = GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: KaColors.onSurface,
  );

  static TextStyle titleMedium = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: KaColors.onSurface,
    letterSpacing: 0.15,
  );

  static TextStyle titleSmall = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: KaColors.onSurface,
    letterSpacing: 0.1,
  );

  // ---------- Body (Inter) ----------
  // All functional text
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: KaColors.onSurface,
    letterSpacing: 0.15,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: KaColors.onSurface,
    letterSpacing: 0.25,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: KaColors.onSurfaceVariant,
    letterSpacing: 0.4,
  );

  // ---------- Label (Inter) ----------
  // Micro-data: file sizes, timestamps
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: KaColors.onSurface,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: KaColors.onSurfaceVariant,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: KaColors.onSurfaceVariant,
    letterSpacing: 0.5,
  );
}
