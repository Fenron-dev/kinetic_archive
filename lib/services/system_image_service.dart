import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Creates platform-specific system images.
/// Windows: disk2vhd → VHDX
/// Linux:   dd + gzip → .img.gz
class SystemImageService {
  static String? _disk2vhdPath;

  /// Windows only: extract disk2vhd from assets.
  Future<String> get _disk2vhd async {
    if (_disk2vhdPath != null && await File(_disk2vhdPath!).exists()) {
      return _disk2vhdPath!;
    }
    final cacheDir = await getApplicationSupportDirectory();
    final binDir = Directory(p.join(cacheDir.path, 'binaries'));
    await binDir.create(recursive: true);

    final outPath = p.join(binDir.path, 'disk2vhd.exe');
    final outFile = File(outPath);
    if (!await outFile.exists()) {
      final data = await rootBundle.load('assets/binaries/windows/disk2vhd.exe');
      await outFile.writeAsBytes(data.buffer.asUint8List());
    }
    _disk2vhdPath = outPath;
    return outPath;
  }

  /// Creates a system image and streams progress updates.
  /// [outputDir] is the destination directory.
  /// [driveOrPartition] is the source (e.g. `C:` on Windows, `/dev/sda` on Linux).
  Stream<SysImageProgress> createImage({
    required String outputDir,
    required String driveOrPartition,
  }) {
    if (Platform.isWindows) {
      return _createVhdx(outputDir: outputDir, drive: driveOrPartition);
    } else if (Platform.isLinux) {
      return _createDdImage(outputDir: outputDir, device: driveOrPartition);
    } else {
      return Stream.error(
        UnsupportedError('System Image nur auf Windows und Linux unterstützt.'),
      );
    }
  }

  Stream<SysImageProgress> _createVhdx({
    required String outputDir,
    required String drive,
  }) async* {
    final bin = await _disk2vhd;
    final fileName = 'system_image_${DateTime.now().millisecondsSinceEpoch}.vhdx';
    final outputPath = p.join(outputDir, fileName);

    // disk2vhd syntax: disk2vhd <drive> <vhdxfile> [options]
    final process = await Process.start(bin, [
      drive,
      outputPath,
      '-accepteula',
    ]);

    // disk2vhd does not output reliable progress — report indeterminate
    yield const SysImageProgress(percent: -1, status: 'VHDX wird erstellt…');

    await process.stdout.drain();
    await process.stderr.drain();
    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw SystemImageException('disk2vhd exited with code $exitCode');
    }
    yield SysImageProgress(percent: 100, status: 'Fertig: $outputPath', done: true);
  }

  Stream<SysImageProgress> _createDdImage({
    required String outputDir,
    required String device,
  }) async* {
    final fileName = 'system_image_${DateTime.now().millisecondsSinceEpoch}.img.gz';
    final outputPath = p.join(outputDir, fileName);

    // dd | gzip — requires root (pkexec or sudo pre-auth)
    final process = await Process.start(
      'bash',
      ['-c', 'dd if=$device bs=4M status=progress 2>&1 | gzip -1 > "$outputPath"'],
      runInShell: false,
    );

    String lastLine = '';
    await for (final data in process.stdout) {
      lastLine = String.fromCharCodes(data).trim();
      // dd status=progress outputs: "X bytes (Y GB, Z GiB) copied, N s, M MB/s"
      yield SysImageProgress(percent: -1, status: lastLine);
    }
    await process.stderr.drain();
    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw SystemImageException('dd/gzip exited with code $exitCode');
    }
    yield SysImageProgress(percent: 100, status: 'Fertig: $outputPath', done: true);
  }

  /// Returns available drives/partitions on the current platform.
  Future<List<String>> listDrives() async {
    if (Platform.isWindows) {
      final result = await Process.run(
        'wmic',
        ['logicaldisk', 'get', 'name'],
        runInShell: true,
      );
      return (result.stdout as String)
          .split('\n')
          .map((l) => l.trim())
          .where((l) => RegExp(r'^[A-Z]:$').hasMatch(l))
          .toList();
    } else if (Platform.isLinux) {
      final result = await Process.run(
        'lsblk',
        ['-d', '-n', '-o', 'PATH,SIZE,TYPE'],
        runInShell: false,
      );
      return (result.stdout as String)
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
    }
    return [];
  }
}

class SysImageProgress {
  const SysImageProgress({
    required this.percent,
    required this.status,
    this.done = false,
  });
  /// -1 = indeterminate
  final int percent;
  final String status;
  final bool done;
}

class SystemImageException implements Exception {
  const SystemImageException(this.message);
  final String message;
  @override
  String toString() => 'SystemImageException: $message';
}

final systemImageServiceProvider = Provider<SystemImageService>(
  (_) => SystemImageService(),
);
