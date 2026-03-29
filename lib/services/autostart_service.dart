import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Registers / unregisters the app for system autostart.
/// Windows: HKCU\Software\Microsoft\Windows\CurrentVersion\Run
/// Linux:   ~/.config/autostart/kinetic_archive.desktop
class AutostartService {
  static const _appName = 'KineticArchive';

  Future<void> enable() async {
    if (Platform.isWindows) {
      await _windowsSet(enabled: true);
    } else if (Platform.isLinux) {
      await _linuxSet(enabled: true);
    }
  }

  Future<void> disable() async {
    if (Platform.isWindows) {
      await _windowsSet(enabled: false);
    } else if (Platform.isLinux) {
      await _linuxSet(enabled: false);
    }
  }

  Future<bool> isEnabled() async {
    if (Platform.isWindows) {
      final result = await Process.run(
        'reg',
        ['query', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run', '/v', _appName],
        runInShell: true,
      );
      return result.exitCode == 0;
    } else if (Platform.isLinux) {
      return await File(_linuxDesktopPath).exists();
    }
    return false;
  }

  Future<void> _windowsSet({required bool enabled}) async {
    final executablePath = Platform.resolvedExecutable;
    if (enabled) {
      await Process.run(
        'reg',
        [
          'add',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
          '/v', _appName,
          '/t', 'REG_SZ',
          '/d', '"$executablePath"',
          '/f',
        ],
        runInShell: true,
      );
    } else {
      await Process.run(
        'reg',
        [
          'delete',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
          '/v', _appName,
          '/f',
        ],
        runInShell: true,
      );
    }
  }

  String get _linuxDesktopPath {
    final home = Platform.environment['HOME'] ?? '/tmp';
    return p.join(home, '.config', 'autostart', 'kinetic_archive.desktop');
  }

  Future<void> _linuxSet({required bool enabled}) async {
    final desktopFile = File(_linuxDesktopPath);
    if (enabled) {
      final executablePath = Platform.resolvedExecutable;
      await desktopFile.parent.create(recursive: true);
      await desktopFile.writeAsString('''[Desktop Entry]
Type=Application
Name=The Kinetic Archive
Exec=$executablePath
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
''');
    } else {
      if (await desktopFile.exists()) await desktopFile.delete();
    }
  }
}

final autostartServiceProvider = Provider<AutostartService>(
  (_) => AutostartService(),
);
