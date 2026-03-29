import 'package:flutter/material.dart';

/// Design tokens from DESIGN.md — "The Silent Sentinel" color system.
/// All surfaces use tonal layering (no 1px borders).
abstract final class KaColors {
  // ---------- Surface Hierarchy (darkest → most elevated) ----------
  static const surface = Color(0xFF060E20); // Base layer / sidebar
  static const surfaceContainerLowest = Color(0xFF000000); // Input fields / recessed
  static const surfaceContainerLow = Color(0xFF091328); // Adjacent sections
  static const surfaceContainer = Color(0xFF0F1930); // Primary containers
  static const surfaceContainerHigh = Color(0xFF131E38); // Floating cards
  static const surfaceContainerHighest = Color(0xFF192540); // Interactive elevated

  // ---------- Accent Colors ----------
  static const primary = Color(0xFF6DDDFF); // Electric cyan — CTA, active, "Complete"
  static const primaryContainer = Color(0xFF00D2FD); // Gradient endpoint for CTAs
  static const tertiary = Color(0xFF82A3FF); // Blue — "Syncing" status
  static const error = Color(0xFFFF716C); // ONLY for hardware failure / data loss

  // ---------- Surface Tint & Variants ----------
  static const surfaceVariant = Color(0xFF1A2B4A); // Glassmorphism base
  static const surfaceTint = Color(0xFF6DDDFF); // Same as primary — for glow effects
  static const outlineVariant = Color(0xFF40485D); // Ghost borders (use at 15% opacity)

  // ---------- Text Colors ----------
  static const onSurface = Color(0xFFDEE5FF); // Primary text — NEVER pure white
  static const onSurfaceVariant = Color(0xFF8A95B0); // Secondary / muted text
  static const onPrimary = Color(0xFF003040); // Text on primary buttons
  static const onError = Color(0xFF1A0000); // Text on error surfaces

  // ---------- Status Colors ----------
  static const statusSuccess = primary; // Completed backup
  static const statusSyncing = tertiary; // In progress
  static const statusWarning = Color(0xFFFFB84D); // Warnings
  static const statusError = error; // Failures

  // ---------- Gradient ----------
  static const primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [primary, primaryContainer],
  );
}
