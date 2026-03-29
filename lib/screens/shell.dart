import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../providers/retention_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'system_image/system_image_screen.dart';
import 'new_job/new_job_screen.dart';
import 'logs/logs_screen.dart';
import 'settings/settings_screen.dart';

final _navIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Listen for retention proposals after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(retentionProposalProvider, (prev, next) {
        if (next != null && mounted) _showRetentionDialog(next);
      });
    });
  }

  Future<void> _showRetentionDialog(RetentionProposal proposal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RetentionDialog(proposal: proposal),
    );

    if (confirmed == true) {
      for (final entity in proposal.filesToDelete) {
        try {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        } catch (_) {}
      }
    }

    // Clear proposal regardless of choice
    ref.read(retentionProposalProvider.notifier).state = null;
  }

  static const _screens = [
    DashboardScreen(),
    SystemImageScreen(),
    NewJobScreen(),
    LogsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(_navIndexProvider);

    return Scaffold(
      backgroundColor: KaColors.surface,
      appBar: _KaAppBar(),
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: _KaNavBar(
        currentIndex: index,
        onTap: (i) => ref.read(_navIndexProvider.notifier).state = i,
      ),
    );
  }
}

class _KaAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: KaColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [KaColors.primary, KaColors.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_rounded, color: KaColors.onPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'The Kinetic Archive',
            style: KaTextStyles.titleMedium.copyWith(
              color: KaColors.onSurface,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _KaNavBar extends StatelessWidget {
  const _KaNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: KaColors.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: Colors.transparent),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.save_outlined),
            selectedIcon: Icon(Icons.save_rounded),
            label: 'System Image',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Neuer Job',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Einstellungen',
          ),
        ],
      ),
    );
  }
}

/// Confirmation dialog shown before deleting old backups.
class _RetentionDialog extends StatelessWidget {
  const _RetentionDialog({required this.proposal});
  final RetentionProposal proposal;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KaColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.delete_sweep_rounded, color: KaColors.statusWarning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Alte Sicherungen löschen?', style: KaTextStyles.titleMedium),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job: ${proposal.jobName}',
              style: KaTextStyles.bodyMedium.copyWith(color: KaColors.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              'Folgende ${proposal.filesToDelete.length} Einträge werden '
              'unwiderruflich gelöscht:',
              style: KaTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: KaColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                itemCount: proposal.filesToDelete.length,
                itemBuilder: (_, i) {
                  final entity = proposal.filesToDelete[i];
                  final isDir = entity is Directory;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          isDir ? Icons.folder_rounded : Icons.archive_rounded,
                          size: 16,
                          color: KaColors.statusWarning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.basename(entity.path),
                            style: KaTextStyles.labelMedium.copyWith(
                              color: KaColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Nur Dateien im Sicherungsordner dieses Jobs werden gelöscht.',
              style: KaTextStyles.labelSmall.copyWith(color: KaColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Behalten',
            style: KaTextStyles.labelLarge.copyWith(color: KaColors.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Löschen',
            style: KaTextStyles.labelLarge.copyWith(
              color: KaColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
