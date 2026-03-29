import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Glassmorphism card: surface_variant at 60% opacity, 24px backdrop blur.
/// Used for hero stats and primary action areas.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 16.0,
    this.opacity = 0.6,
    this.blurSigma = 24.0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double opacity;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: KaColors.surfaceVariant.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: KaColors.outlineVariant.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
