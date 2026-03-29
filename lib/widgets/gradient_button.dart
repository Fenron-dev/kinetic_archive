import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Primary CTA button with cyan gradient (#6dddff → #00d2fd, 135°),
/// xl roundedness (24px), and subtle tint glow on press.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.width,
          height: 52,
          decoration: BoxDecoration(
            gradient: isDisabled
                ? null
                : const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [KaColors.primary, KaColors.primaryContainer],
                  ),
            color: isDisabled ? KaColors.surfaceContainerHighest : null,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDisabled || _pressed
                ? null
                : [
                    BoxShadow(
                      color: KaColors.surfaceTint.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: Offset.zero,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: KaColors.onPrimary,
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, color: KaColors.onPrimary, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.label,
                    style: KaTextStyles.labelLarge.copyWith(
                      color: isDisabled
                          ? KaColors.onSurfaceVariant
                          : KaColors.onPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary button: surfaceContainerHighest background, ghost border.
class SecondaryButton extends StatefulWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.width,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final Color? color;

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final labelColor = widget.color ?? KaColors.onSurface;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.width,
          height: 44,
          decoration: BoxDecoration(
            color: KaColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: KaColors.outlineVariant.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                const SizedBox(width: 12),
                Icon(widget.icon, color: labelColor, size: 18),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.label,
                    style: KaTextStyles.labelLarge.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
