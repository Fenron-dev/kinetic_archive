import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../models/job.dart';
import '../../providers/jobs_provider.dart';
import '../../services/backup_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/pulse_progress_bar.dart';
import '../../widgets/status_badge.dart';
import '../new_job/new_job_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsProvider);
    final backupService = ref.read(backupServiceProvider);
    final runningJobs = jobs.where((j) => j.status == JobStatus.running).toList();
    final pendingJobs = jobs.where((j) => j.status != JobStatus.running).toList();
    final lastSuccess = jobs.where((j) => j.lastRun != null).toList()
      ..sort((a, b) => b.lastRun!.compareTo(a.lastRun!));

    return Scaffold(
      backgroundColor: KaColors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              // Hero Stats
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _HeroStats(
                    jobs: jobs,
                    lastBackup: lastSuccess.isNotEmpty ? lastSuccess.first.lastRun : null,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              // Running jobs
              if (runningJobs.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Text('Aktiv', style: KaTextStyles.titleSmall.copyWith(
                      color: KaColors.onSurfaceVariant,
                    )),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: runningJobs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _JobTile(job: runningJobs[i]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
              // Queue
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text('Warteschlange', style: KaTextStyles.titleSmall.copyWith(
                        color: KaColors.onSurfaceVariant,
                      )),
                      const Spacer(),
                      if (pendingJobs.isNotEmpty)
                        Text(
                          '${pendingJobs.length} Jobs',
                          style: KaTextStyles.labelSmall,
                        ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              if (pendingJobs.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _EmptyQueue(
                      onAddJob: () {
                        // Navigate to new job tab
                      },
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: pendingJobs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _JobTile(job: pendingJobs[i]),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          // FAB "Alle starten"
          if (jobs.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: GradientButton(
                label: 'ALLE STARTEN',
                icon: Icons.play_arrow_rounded,
                onPressed: () => backupService.runAll(jobs),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.jobs, this.lastBackup});
  final List<BackupJob> jobs;
  final DateTime? lastBackup;

  @override
  Widget build(BuildContext context) {
    final hasError = jobs.any((j) => j.status == JobStatus.error);
    final statusLabel = hasError ? 'Fehler' : 'Sicher';
    final statusColor = hasError ? KaColors.error : KaColors.primary;

    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Backup Status', style: KaTextStyles.labelMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      hasError ? Icons.error_rounded : Icons.shield_rounded,
                      color: statusColor,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusLabel,
                      style: KaTextStyles.headlineSmall.copyWith(color: statusColor),
                    ),
                  ],
                ),
                if (lastBackup != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Zuletzt: ${DateFormat('dd.MM.yy HH:mm').format(lastBackup!)}',
                    style: KaTextStyles.labelSmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jobs gesamt', style: KaTextStyles.labelMedium),
                const SizedBox(height: 8),
                Text(
                  '${jobs.length}',
                  style: KaTextStyles.headlineSmall.copyWith(color: KaColors.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  '${jobs.where((j) => j.status == JobStatus.running).length} aktiv',
                  style: KaTextStyles.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _JobTile extends ConsumerWidget {
  const _JobTile({required this.job});
  final BackupJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = job.status == JobStatus.running;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isRunning
            ? KaColors.surfaceContainerHigh
            : KaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.name, style: KaTextStyles.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        '${job.sourcePath} → ${job.destinationPath}',
                        style: KaTextStyles.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: job.status),
                const SizedBox(width: 8),
                _JobActions(job: job),
              ],
            ),
            if (isRunning) ...[
              const SizedBox(height: 14),
              PulseProgressBar(value: job.progress),
              const SizedBox(height: 6),
              Text(
                '${(job.progress * 100).round()}%',
                style: KaTextStyles.labelSmall.copyWith(color: KaColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JobActions extends ConsumerWidget {
  const _JobActions({required this.job});
  final BackupJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (job.status == JobStatus.running)
          _IconBtn(
            icon: Icons.stop_rounded,
            color: KaColors.error,
            tooltip: 'Stoppen',
            onTap: () => ref.read(backupServiceProvider).cancelJob(job.id),
          )
        else ...[
          _IconBtn(
            icon: Icons.play_arrow_rounded,
            color: KaColors.primary,
            tooltip: 'Starten',
            onTap: () => ref.read(backupServiceProvider).runJob(job),
          ),
          _IconBtn(
            icon: Icons.edit_rounded,
            color: KaColors.onSurfaceVariant,
            tooltip: 'Bearbeiten',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => NewJobDialog(existingJob: job),
              );
            },
          ),
          _IconBtn(
            icon: Icons.delete_outline_rounded,
            color: KaColors.onSurfaceVariant,
            tooltip: 'Löschen',
            onTap: () => ref.read(jobsProvider.notifier).deleteJob(job.id),
          ),
        ],
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.onAddJob});
  final VoidCallback onAddJob;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: KaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, color: KaColors.onSurfaceVariant, size: 40),
          const SizedBox(height: 12),
          Text('Keine Jobs in der Warteschlange', style: KaTextStyles.bodyMedium.copyWith(
            color: KaColors.onSurfaceVariant,
          )),
        ],
      ),
    );
  }
}
