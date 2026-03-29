import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import 'storage_provider.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return ref.read(storageServiceProvider).loadSettings();
  }

  Future<void> update(AppSettings updated) async {
    state = updated;
    await ref.read(storageServiceProvider).saveSettings(updated);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
