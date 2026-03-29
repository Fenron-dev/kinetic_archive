import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

enum JobStatus { running, pending, ready, success, warning, error, cancelled }

extension JobStatusX on JobStatus {
  String get label => switch (this) {
        JobStatus.running => 'RUNNING',
        JobStatus.pending => 'SCHEDULED',
        JobStatus.ready => 'READY',
        JobStatus.success => 'COMPLETE',
        JobStatus.warning => 'WARNING',
        JobStatus.error => 'FAILED',
        JobStatus.cancelled => 'CANCELLED',
      };

  Color get color => switch (this) {
        JobStatus.running => KaColors.primary,
        JobStatus.pending => KaColors.tertiary,
        JobStatus.ready => KaColors.onSurfaceVariant,
        JobStatus.success => KaColors.statusSuccess,
        JobStatus.warning => KaColors.statusWarning,
        JobStatus.error => KaColors.statusError,
        JobStatus.cancelled => KaColors.onSurfaceVariant,
      };

  IconData get icon => switch (this) {
        JobStatus.running => Icons.play_arrow_rounded,
        JobStatus.pending => Icons.schedule_rounded,
        JobStatus.ready => Icons.check_circle_outline_rounded,
        JobStatus.success => Icons.check_circle_rounded,
        JobStatus.warning => Icons.warning_amber_rounded,
        JobStatus.error => Icons.error_rounded,
        JobStatus.cancelled => Icons.cancel_outlined,
      };
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.compact = false});

  final JobStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: status.color, size: compact ? 11 : 13),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: KaTextStyles.labelSmall.copyWith(
              color: status.color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
