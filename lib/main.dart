import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'providers/storage_provider.dart';
import 'providers/logs_provider.dart';
import 'services/scheduler_service.dart';
import 'services/tray_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Window setup
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(640, 520));
  await windowManager.setTitle('The Kinetic Archive');
  await windowManager.setTitleBarStyle(TitleBarStyle.normal);

  // Storage init (must happen before ProviderScope reads it)
  final storage = StorageService();
  await storage.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const _AppBootstrap(),
    ),
  );
}

/// Initializes services that need the Riverpod scope available.
class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap();

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initServices();
  }

  Future<void> _initServices() async {
    // Load initial logs
    await ref.read(logsProvider.notifier).refresh();

    // Start scheduler
    ref.read(schedulerServiceProvider).start();

    // Init tray (desktop only) — optional, fails gracefully if
    // icon is missing or the desktop environment has no tray support
    if (Platform.isWindows || Platform.isLinux) {
      try {
        await ref.read(trayServiceProvider).init();
      } catch (_) {
        // Tray not available (e.g. GNOME without AppIndicator, missing icon)
      }
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    final settings = ref.read(storageServiceProvider).loadSettings();
    if (settings.minimizeToTray && (Platform.isWindows || Platform.isLinux)) {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const KineticArchiveApp();
  }
}
