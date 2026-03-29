import 'package:freezed_annotation/freezed_annotation.dart';
import '../widgets/status_badge.dart';
import 'schedule.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class BackupJob with _$BackupJob {
  const factory BackupJob({
    required String id,
    required String name,
    required String sourcePath,
    required String destinationPath,
    @Default(false) bool useCompression,
    @Default(false) bool useEncryption,
    String? encryptionPassword,
    JobSchedule? schedule,
    // Naming
    @Default(false) bool appendTimestamp,
    // Retention
    @Default(false) bool retentionEnabled,
    @Default(3) int retentionCount,
    @Default(JobStatus.ready) JobStatus status,
    @Default(0.0) double progress,
    DateTime? lastRun,
    DateTime? nextRun,
    String? lastError,
    @Default(0) int totalBytes,
    @Default(0) int processedBytes,
  }) = _BackupJob;

  factory BackupJob.fromJson(Map<String, dynamic> json) =>
      _$BackupJobFromJson(json);
}
