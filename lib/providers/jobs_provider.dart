import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/job.dart';
import '../models/schedule.dart';
import '../widgets/status_badge.dart';
import 'storage_provider.dart';

const _uuid = Uuid();

class JobsNotifier extends Notifier<List<BackupJob>> {
  @override
  List<BackupJob> build() {
    return ref.read(storageServiceProvider).loadJobs();
  }

  Future<BackupJob> addJob({
    required String name,
    required String sourcePath,
    required String destinationPath,
    bool useCompression = false,
    bool useEncryption = false,
    String? encryptionPassword,
    bool appendTimestamp = false,
    bool retentionEnabled = false,
    int retentionCount = 3,
    JobSchedule? schedule,
  }) async {
    final job = BackupJob(
      id: _uuid.v4(),
      name: name,
      sourcePath: sourcePath,
      destinationPath: destinationPath,
      useCompression: useCompression,
      useEncryption: useEncryption,
      encryptionPassword: encryptionPassword,
      appendTimestamp: appendTimestamp,
      retentionEnabled: retentionEnabled,
      retentionCount: retentionCount,
      schedule: schedule,
      status: JobStatus.ready,
    );
    final storage = ref.read(storageServiceProvider);
    await storage.saveJob(job);
    state = [...state, job];
    return job;
  }

  Future<void> updateJob(BackupJob updated) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveJob(updated);
    state = [
      for (final j in state)
        if (j.id == updated.id) updated else j,
    ];
  }

  Future<void> deleteJob(String id) async {
    final storage = ref.read(storageServiceProvider);
    await storage.deleteJob(id);
    state = state.where((j) => j.id != id).toList();
  }

  void updateProgress(String jobId, double progress, {int? processedBytes}) {
    state = [
      for (final j in state)
        if (j.id == jobId)
          j.copyWith(
            progress: progress,
            status: JobStatus.running,
            processedBytes: processedBytes ?? j.processedBytes,
          )
        else
          j,
    ];
  }

  void markJobStatus(String jobId, JobStatus status, {String? error}) {
    final now = DateTime.now();
    state = [
      for (final j in state)
        if (j.id == jobId)
          j.copyWith(
            status: status,
            progress: status == JobStatus.success ? 1.0 : j.progress,
            lastRun: status == JobStatus.success || status == JobStatus.error
                ? now
                : j.lastRun,
            lastError: error,
          )
        else
          j,
    ];
    final updated = state.firstWhere((j) => j.id == jobId);
    ref.read(storageServiceProvider).saveJob(updated);
  }

  Future<void> importJobs(List<BackupJob> jobs) async {
    final storage = ref.read(storageServiceProvider);
    // Merge: keep existing, add/overwrite with imported
    final existing = {for (final j in state) j.id: j};
    for (final job in jobs) {
      existing[job.id] = job;
    }
    final merged = existing.values.toList();
    await storage.saveAllJobs(merged);
    state = merged;
  }
}

final jobsProvider = NotifierProvider<JobsNotifier, List<BackupJob>>(JobsNotifier.new);
