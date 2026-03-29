import 'package:freezed_annotation/freezed_annotation.dart';

part 'log_entry.freezed.dart';
part 'log_entry.g.dart';

enum LogLevel { success, warning, error, info }

extension LogLevelX on LogLevel {
  String get label => name.toUpperCase();
}

@freezed
class LogEntry with _$LogEntry {
  const factory LogEntry({
    required String id,
    required DateTime timestamp,
    required LogLevel level,
    required String jobName,
    required String message,
    String? jobId,
    String? details,
  }) = _LogEntry;

  factory LogEntry.fromJson(Map<String, dynamic> json) =>
      _$LogEntryFromJson(json);
}
