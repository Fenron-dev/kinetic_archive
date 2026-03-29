import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import '../models/job.dart';
import '../models/log_entry.dart';
import '../models/app_settings.dart';

/// Persistent storage layer.
/// - Hive: jobs + settings (fast key-value, JSON serialized)
/// - SQLite: log history (queryable, filterable)
class StorageService {
  static const _jobsBox = 'jobs';
  static const _settingsBox = 'settings';
  static const _settingsKey = 'app_settings';

  late final Box<String> _jobs;
  late final Box<String> _settings;
  late final Database _db;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Desktop platforms need the FFI database factory
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    await Hive.initFlutter();
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(p.join(appDir.path, 'kinetic_archive', 'hive'));

    _jobs = await Hive.openBox<String>(_jobsBox);
    _settings = await Hive.openBox<String>(_settingsBox);

    final dbPath = p.join(appDir.path, 'kinetic_archive', 'logs.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE logs (
            id TEXT PRIMARY KEY,
            timestamp INTEGER NOT NULL,
            level TEXT NOT NULL,
            job_name TEXT NOT NULL,
            message TEXT NOT NULL,
            job_id TEXT,
            details TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_logs_timestamp ON logs(timestamp DESC)');
        await db.execute('CREATE INDEX idx_logs_level ON logs(level)');
      },
    );
    _initialized = true;
  }

  // ---------- Jobs ----------

  List<BackupJob> loadJobs() {
    return _jobs.values
        .map((raw) => BackupJob.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveJob(BackupJob job) async {
    await _jobs.put(job.id, jsonEncode(job.toJson()));
  }

  Future<void> deleteJob(String id) async {
    await _jobs.delete(id);
  }

  Future<void> saveAllJobs(List<BackupJob> jobs) async {
    await _jobs.clear();
    final map = {for (final j in jobs) j.id: jsonEncode(j.toJson())};
    await _jobs.putAll(map);
  }

  // ---------- Settings ----------

  AppSettings loadSettings() {
    final raw = _settings.get(_settingsKey);
    if (raw == null) return AppSettings.defaults;
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settings.put(_settingsKey, jsonEncode(settings.toJson()));
  }

  // ---------- Logs ----------

  Future<void> insertLog(LogEntry entry) async {
    await _db.insert(
      'logs',
      {
        'id': entry.id,
        'timestamp': entry.timestamp.millisecondsSinceEpoch,
        'level': entry.level.name,
        'job_name': entry.jobName,
        'message': entry.message,
        'job_id': entry.jobId,
        'details': entry.details,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LogEntry>> loadLogs({LogLevel? filterLevel, int limit = 200}) async {
    final where = filterLevel != null ? 'level = ?' : null;
    final whereArgs = filterLevel != null ? [filterLevel.name] : null;

    final rows = await _db.query(
      'logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(_rowToLogEntry).toList();
  }

  Future<void> clearLogs() async {
    await _db.delete('logs');
  }

  LogEntry _rowToLogEntry(Map<String, dynamic> row) {
    return LogEntry(
      id: row['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      level: LogLevel.values.byName(row['level'] as String),
      jobName: row['job_name'] as String,
      message: row['message'] as String,
      jobId: row['job_id'] as String?,
      details: row['details'] as String?,
    );
  }

  // ---------- Config export / import ----------

  String exportJobsAsJson(List<BackupJob> jobs) {
    final safeJobs = jobs.map((j) => j.copyWith(encryptionPassword: null).toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert({'jobs': safeJobs});
  }

  List<BackupJob> importJobsFromJson(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = data['jobs'] as List<dynamic>;
    return list
        .map((e) => BackupJob.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
