import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/jobs_provider.dart';
import 'backup_service.dart';

/// Manages the system tray icon and context menu.
class TrayService with TrayListener {
  TrayService(this._ref);

  final Ref _ref;

  Future<void> init() async {
    if (!Platform.isWindows && !Platform.isLinux) return;

    trayManager.addListener(this);

    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/icons/tray_icon.ico'
          : 'assets/icons/tray_icon.png',
    );
    await trayManager.setToolTip('The Kinetic Archive');
    await _updateMenu();
  }

  Future<void> _updateMenu() async {
    await trayManager.setContextMenu(
      Menu(items: [
        MenuItem(
          key: 'show',
          label: 'Dashboard öffnen',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'run_all',
          label: 'Alle Jobs starten',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit',
          label: 'Beenden',
        ),
      ]),
    );
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        windowManager.show();
        windowManager.focus();
      case 'run_all':
        final jobs = _ref.read(jobsProvider);
        final service = _ref.read(backupServiceProvider);
        service.runAll(jobs);
      case 'quit':
        trayManager.destroy();
        exit(0);
    }
  }

  void dispose() {
    trayManager.removeListener(this);
    trayManager.destroy();
  }
}

final trayServiceProvider = Provider<TrayService>((ref) {
  final s = TrayService(ref);
  ref.onDispose(s.dispose);
  return s;
});
