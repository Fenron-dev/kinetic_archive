import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Wraps the bundled 7za binary for compression and encryption operations.
/// Extracts the platform binary from assets on first use.
class ZipService {
  static String? _binaryPath;

  /// Resolves the 7za binary path.
  /// Priority: (1) system-installed 7za/7zz, (2) bundled asset binary.
  Future<String> get binaryPath async {
    if (_binaryPath != null && await File(_binaryPath!).exists()) {
      return _binaryPath!;
    }

    // 1. Check for system-installed 7za or 7zz (Linux/macOS)
    if (!Platform.isWindows) {
      for (final candidate in ['7za', '7zz', '7z']) {
        final result = await Process.run('which', [candidate]);
        if (result.exitCode == 0) {
          _binaryPath = (result.stdout as String).trim();
          return _binaryPath!;
        }
      }
    }

    // 2. Fall back to bundled asset binary
    final cacheDir = await getApplicationSupportDirectory();
    final binDir = Directory(p.join(cacheDir.path, 'binaries'));
    await binDir.create(recursive: true);

    final binaryName = Platform.isWindows ? '7za.exe' : '7za';
    final assetPath = Platform.isWindows
        ? 'assets/binaries/windows/$binaryName'
        : 'assets/binaries/linux/$binaryName';

    final outPath = p.join(binDir.path, binaryName);
    final outFile = File(outPath);

    if (!await outFile.exists()) {
      final data = await rootBundle.load(assetPath);
      await outFile.writeAsBytes(data.buffer.asUint8List());
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['+x', outPath]);
      }
    }

    _binaryPath = outPath;
    return outPath;
  }

  /// Compresses [sourcePath] into [archivePath].
  /// If [password] is provided, AES-256 encryption is used.
  /// Yields progress updates as percentages (0-100) via a stream.
  Stream<ZipProgress> compress({
    required String sourcePath,
    required String archivePath,
    String? password,
  }) async* {
    final bin = await binaryPath;

    final args = [
      'a', // add to archive
      '-t7z', // format
      '-mx=5', // compression level (0=store, 9=max)
      '-mmt=on', // multithreading
      if (password != null) ...[
        '-mhe=on', // encrypt headers
        '-p$password',
      ],
      archivePath,
      sourcePath,
    ];

    final process = await Process.start(bin, args);
    String buffer = '';

    await for (final data in process.stdout) {
      buffer += String.fromCharCodes(data);
      // 7zip outputs progress as e.g. " 34%"
      final matches = RegExp(r'(\d+)%').allMatches(buffer);
      for (final m in matches) {
        final pct = int.tryParse(m.group(1) ?? '');
        if (pct != null) yield ZipProgress(percent: pct);
      }
      buffer = '';
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final stderr = await process.stderr.transform(const SystemEncoding().decoder).join();
      throw ZipException('7za exited with code $exitCode: $stderr');
    }
    yield const ZipProgress(percent: 100, done: true);
  }

  /// Tests the integrity of an archive.
  Future<bool> testArchive(String archivePath, {String? password}) async {
    final bin = await binaryPath;
    final args = [
      't', // test
      if (password != null) '-p$password',
      archivePath,
    ];
    final result = await Process.run(bin, args);
    return result.exitCode == 0;
  }
}

class ZipProgress {
  const ZipProgress({required this.percent, this.done = false});
  final int percent;
  final bool done;
}

class ZipException implements Exception {
  const ZipException(this.message);
  final String message;
  @override
  String toString() => 'ZipException: $message';
}
