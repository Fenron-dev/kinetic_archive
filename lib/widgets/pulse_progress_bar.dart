import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Animated progress bar with primary→tertiary gradient and a cyan glow
/// at the leading edge to signal active data movement.
class PulseProgressBar extends StatefulWidget {
  const PulseProgressBar({
    super.key,
    required this.value, // 0.0 – 1.0
    this.height = 6.0,
    this.animate = true,
  });

  final double value;
  final double height;
  final bool animate;

  @override
  State<PulseProgressBar> createState() => _PulseProgressBarState();
}

class _PulseProgressBarState extends State<PulseProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    if (widget.animate && widget.value > 0 && widget.value < 1) {
      _glowCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && widget.value > 0 && widget.value < 1) {
      if (!_glowCtrl.isAnimating) _glowCtrl.repeat(reverse: true);
    } else {
      _glowCtrl.stop();
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final filledWidth = constraints.maxWidth * widget.value.clamp(0.0, 1.0);
        return AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, _) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: KaColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: filledWidth,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [KaColors.primary, KaColors.tertiary],
                      ),
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      boxShadow: widget.value > 0
                          ? [
                              BoxShadow(
                                color: KaColors.surfaceTint.withValues(
                                  alpha: _glowAnim.value * 0.6,
                                ),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
