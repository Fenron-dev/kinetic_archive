import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../models/log_entry.dart';
import '../../providers/logs_provider.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(logFilterProvider);
    final logs = ref.watch(logsProvider);

    return Scaffold(
      backgroundColor: KaColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Logübersicht', style: KaTextStyles.headlineSmall),
                    Text('System Status', style: KaTextStyles.bodySmall),
                  ],
                ),
                const Spacer(),
                if (logs.isNotEmpty)
                  _IconActionButton(
                    icon: Icons.delete_sweep_rounded,
                    label: 'ALLE LÖSCHEN',
                    color: KaColors.error,
                    onTap: () => _confirmClear(context, ref),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Filter bar
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(
                  label: 'Alle',
                  active: filter == null,
                  onTap: () {
                    ref.read(logFilterProvider.notifier).state = null;
                    ref.read(logsProvider.notifier).refresh();
                  },
                ),
                const SizedBox(width: 8),
                for (final level in LogLevel.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: level.label,
                      active: filter == level,
                      color: _levelColor(level),
                      onTap: () {
                        ref.read(logFilterProvider.notifier).state = level;
                        ref.read(logsProvider.notifier).refresh(filter: level);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Log list
          Expanded(
            child: logs.isEmpty
                ? _EmptyLogs()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: logs.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _LogTile(entry: logs[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KaColors.surfaceContainerHigh,
        title: Text('Alle Logs löschen?', style: KaTextStyles.titleMedium),
        content: Text(
          'Dieser Vorgang kann nicht rückgängig gemacht werden.',
          style: KaTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Abbrechen',
                style: KaTextStyles.labelLarge.copyWith(color: KaColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Löschen',
                style: KaTextStyles.labelLarge.copyWith(color: KaColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(logsProvider.notifier).clearAll();
    }
  }

  Color _levelColor(LogLevel level) => switch (level) {
        LogLevel.success => KaColors.statusSuccess,
        LogLevel.warning => KaColors.statusWarning,
        LogLevel.error => KaColors.statusError,
        LogLevel.info => KaColors.tertiary,
      };
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});
  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final (color, icon, bg) = switch (entry.level) {
      LogLevel.success => (KaColors.statusSuccess, Icons.check_circle_rounded, KaColors.surfaceContainer),
      LogLevel.warning => (KaColors.statusWarning, Icons.warning_amber_rounded, KaColors.surfaceContainer),
      LogLevel.error => (KaColors.error, Icons.error_rounded, KaColors.error.withValues(alpha: 0.08)),
      LogLevel.info => (KaColors.tertiary, Icons.info_rounded, KaColors.surfaceContainer),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.jobName,
                        style: KaTextStyles.titleSmall.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm:ss').format(entry.timestamp),
                      style: KaTextStyles.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  entry.message,
                  style: KaTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, this.color, this.onTap});
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? KaColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.15)
              : KaColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: KaTextStyles.labelMedium.copyWith(
            color: active ? activeColor : KaColors.onSurfaceVariant,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: KaTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLogs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, color: KaColors.onSurfaceVariant, size: 48),
          const SizedBox(height: 12),
          Text(
            'Noch keine Logs vorhanden.',
            style: KaTextStyles.bodyMedium.copyWith(color: KaColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
