import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log_entry.dart';
import 'storage_provider.dart';

final logFilterProvider = StateProvider<LogLevel?>((ref) => null);

class LogsNotifier extends Notifier<List<LogEntry>> {
  @override
  List<LogEntry> build() {
    // Load synchronously from an already-initialized DB.
    // Actual async load happens via refresh().
    return [];
  }

  Future<void> refresh({LogLevel? filter}) async {
    final storage = ref.read(storageServiceProvider);
    state = await storage.loadLogs(filterLevel: filter);
  }

  Future<void> addEntry(LogEntry entry) async {
    final storage = ref.read(storageServiceProvider);
    await storage.insertLog(entry);
    state = [entry, ...state];
  }

  Future<void> clearAll() async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearLogs();
    state = [];
  }
}

final logsProvider = NotifierProvider<LogsNotifier, List<LogEntry>>(LogsNotifier.new);
