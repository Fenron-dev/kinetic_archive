import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/job.dart';
import '../models/log_entry.dart';
import '../widgets/status_badge.dart';
import '../providers/jobs_provider.dart';
import '../providers/logs_provider.dart';
import '../providers/retention_provider.dart';
import 'zip_service.dart';

const _uuid = Uuid();
final _tsFmt = DateFormat('yyyy-MM-dd_HH-mm-ss');

/// Returns a filesystem-safe prefix derived from the job name.
/// Used to identify which files in the destination belong to this job.
String jobPrefix(String jobName) =>
    jobName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+$'), '');

/// Orchestrates backup job execution.
/// Handles plain copy and 7zip compression modes.
class BackupService {
  BackupService(this._ref);

  final Ref _ref;
  final ZipService _zip = ZipService();
  final Map<String, bool> _cancelTokens = {};

  Future<void> runJob(BackupJob job) async {
    if (job.status == JobStatus.running) return;

    _cancelTokens[job.id] = false;
    _ref.read(jobsProvider.notifier).markJobStatus(job.id, JobStatus.running);

    try {
      if (job.useCompression) {
        await _runCompressedBackup(job);
      } else {
        await _runFileCopy(job);
      }

      _ref.read(jobsProvider.notifier).markJobStatus(job.id, JobStatus.success);
      await _log(job, LogLevel.success, 'Backup abgeschlossen.');

      // Disable schedule if runOnce
      if (job.schedule?.runOnce == true) {
        await _ref.read(jobsProvider.notifier).updateJob(
          job.copyWith(schedule: null),
        );
      }

      // Retention check — propose deletion to the user if enabled
      if (job.retentionEnabled) {
        // Use updated job state for retention check
        final currentJob = _ref.read(jobsProvider).firstWhere((j) => j.id == job.id, orElse: () => job);
        await _checkRetention(currentJob);
      }
    } catch (e) {
      if (_cancelTokens[job.id] == true) {
        _ref.read(jobsProvider.notifier).markJobStatus(job.id, JobStatus.cancelled);
        await _log(job, LogLevel.warning, 'Job abgebrochen.');
      } else {
        _ref.read(jobsProvider.notifier).markJobStatus(
          job.id,
          JobStatus.error,
          error: e.toString(),
        );
        await _log(job, LogLevel.error, 'Backup fehlgeschlagen: $e');
      }
    } finally {
      _cancelTokens.remove(job.id);
    }
  }

  void cancelJob(String jobId) {
    _cancelTokens[jobId] = true;
  }

  Future<void> runAll(List<BackupJob> jobs) async {
    for (final job in jobs) {
      if (_cancelTokens[job.id] == true) continue;
      await runJob(job);
    }
  }

  // ---------- Private ----------

  String _buildName(BackupJob job, {required String extension}) {
    final prefix = jobPrefix(job.name);
    if (job.appendTimestamp) {
      return '${prefix}_${_tsFmt.format(DateTime.now())}$extension';
    }
    return '$prefix$extension';
  }

  Future<void> _runCompressedBackup(BackupJob job) async {
    final archiveName = _buildName(job, extension: '.7z');
    final archivePath = p.join(job.destinationPath, archiveName);

    await _ensureDestExists(job.destinationPath);

    await for (final progress in _zip.compress(
      sourcePath: job.sourcePath,
      archivePath: archivePath,
      password: job.useEncryption ? job.encryptionPassword : null,
    )) {
      if (_cancelTokens[job.id] == true) throw const _CancelledException();
      _ref.read(jobsProvider.notifier).updateProgress(job.id, progress.percent / 100);
    }
  }

  Future<void> _runFileCopy(BackupJob job) async {
    final source = Directory(job.sourcePath);
    if (!await source.exists()) {
      throw Exception('Quellverzeichnis existiert nicht: ${job.sourcePath}');
    }

    final destName = _buildName(job, extension: '');
    final destDir = Directory(p.join(job.destinationPath, destName));
    await destDir.create(recursive: true);

    final files = await source.list(recursive: true).where((e) => e is File).toList();
    int done = 0;

    for (final entity in files) {
      if (_cancelTokens[job.id] == true) throw const _CancelledException();

      final file = entity as File;
      final relativePath = p.relative(file.path, from: job.sourcePath);
      final destPath = p.join(destDir.path, relativePath);

      await Directory(p.dirname(destPath)).create(recursive: true);
      await file.copy(destPath);
      done++;

      _ref.read(jobsProvider.notifier).updateProgress(job.id, done / files.length);
    }
  }

  /// Scans the destination for backups belonging to this job and proposes
  /// deletion of all beyond [job.retentionCount].
  /// ONLY looks inside [job.destinationPath] — never outside.
  Future<void> _checkRetention(BackupJob job) async {
    final destDir = Directory(job.destinationPath);
    if (!await destDir.exists()) return;

    final prefix = jobPrefix(job.name);
    final isCompressed = job.useCompression;

    // Collect matching entries directly inside destinationPath (non-recursive)
    final entries = await destDir
        .list(recursive: false)
        .where((e) {
          final name = p.basename(e.path);
          if (!name.startsWith(prefix)) return false;
          if (isCompressed) return e is File && name.endsWith('.7z');
          return e is Directory;
        })
        .toList();

    // Sort oldest first (by name, which encodes the timestamp)
    entries.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    final toDelete = entries.length > job.retentionCount
        ? entries.sublist(0, entries.length - job.retentionCount)
        : <FileSystemEntity>[];

    if (toDelete.isEmpty) return;

    // Hand off to UI for confirmation
    _ref.read(retentionProposalProvider.notifier).state = RetentionProposal(
      jobName: job.name,
      jobId: job.id,
      filesToDelete: toDelete,
    );
  }

  Future<void> _ensureDestExists(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) await dir.create(recursive: true);
  }

  Future<void> _log(BackupJob job, LogLevel level, String message) async {
    final entry = LogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      level: level,
      jobName: job.name,
      message: message,
      jobId: job.id,
    );
    await _ref.read(logsProvider.notifier).addEntry(entry);
  }
}

class _CancelledException implements Exception {
  const _CancelledException();
}

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref),
);
