import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(false) bool autostartWithSystem,
    @Default(true) bool runInBackground,
    @Default(true) bool minimizeToTray,
    @Default(false) bool adminModeEnabled,
    @Default('midnight') String theme,
    DateTime? lastUpdateCheck,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  static const AppSettings defaults = AppSettings();
}
