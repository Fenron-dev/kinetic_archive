import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule.dart';
import '../providers/jobs_provider.dart';
import '../widgets/status_badge.dart';
import 'backup_service.dart';

/// Timer-based scheduler that checks every 60 seconds if any jobs are due.
/// Also handles missed runs on app startup.
class SchedulerService {
  SchedulerService(this._ref);

  final Ref _ref;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _checkAndRun(); // immediate check on start (catches missed runs)
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _checkAndRun());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkAndRun() async {
    final jobs = _ref.read(jobsProvider);
    final now = DateTime.now();
    final backupService = _ref.read(backupServiceProvider);

    for (final job in jobs) {
      if (job.schedule == null) continue;
      if (job.schedule!.frequency == ScheduleFrequency.manual) continue;
      if (job.status == JobStatus.running) continue;

      final nextRun = job.schedule!.nextRunAfter(job.lastRun ?? DateTime(2000));
      if (nextRun.isBefore(now)) {
        // Due — launch without awaiting so jobs can run in parallel
        backupService.runJob(job);
        // Update nextRun
        final updatedJob = job.copyWith(
          nextRun: job.schedule!.nextRunAfter(now),
        );
        await _ref.read(jobsProvider.notifier).updateJob(updatedJob);
      }
    }
  }

  void dispose() => stop();
}

final schedulerServiceProvider = Provider<SchedulerService>(
  (ref) {
    final s = SchedulerService(ref);
    ref.onDispose(s.dispose);
    return s;
  },
);
