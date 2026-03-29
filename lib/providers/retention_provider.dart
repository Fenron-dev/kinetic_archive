import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds a pending retention proposal that needs user confirmation.
/// Set by BackupService after a successful backup; cleared after user acts.
class RetentionProposal {
  const RetentionProposal({
    required this.jobName,
    required this.jobId,
    required this.filesToDelete,
  });

  final String jobName;
  final String jobId;
  final List<FileSystemEntity> filesToDelete;
}

final retentionProposalProvider =
    StateProvider<RetentionProposal?>((ref) => null);
