import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../providers/settings_provider.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/storage_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/secondary_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: KaColors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Einstellungen', style: KaTextStyles.headlineSmall),
            const SizedBox(height: 24),

            // System behavior
            _SettingsCard(
              title: 'Systemverhalten',
              children: [
                _SettingsToggle(
                  label: 'Mit System starten',
                  subtitle: 'App startet automatisch beim Systemstart',
                  value: settings.autostartWithSystem,
                  onChanged: (v) => ref.read(settingsProvider.notifier).update(
                        settings.copyWith(autostartWithSystem: v),
                      ),
                ),
                const SizedBox(height: 12),
                _SettingsToggle(
                  label: 'Im Hintergrund laufen',
                  subtitle: 'Tray / Daemon-Modus aktiv lassen',
                  value: settings.runInBackground,
                  onChanged: (v) => ref.read(settingsProvider.notifier).update(
                        settings.copyWith(runInBackground: v),
                      ),
                ),
                const SizedBox(height: 12),
                _SettingsToggle(
                  label: 'In Tray minimieren',
                  subtitle: 'Fenster schließen minimiert statt beendet',
                  value: settings.minimizeToTray,
                  onChanged: (v) => ref.read(settingsProvider.notifier).update(
                        settings.copyWith(minimizeToTray: v),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Admin mode
            _SettingsCard(
              title: 'Erweiterte Rechte',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Administrator-Modus', style: KaTextStyles.bodyMedium),
                          Text(
                            Platform.isWindows
                                ? 'Für VSS-Snapshots und disk2vhd benötigt'
                                : 'Für dd-Laufwerk-Abbilder benötigt (pkexec)',
                            style: KaTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SecondaryButton(
                      label: settings.adminModeEnabled ? 'AKTIV' : 'AKTIVIEREN',
                      icon: settings.adminModeEnabled
                          ? Icons.check_rounded
                          : Icons.admin_panel_settings_rounded,
                      color: settings.adminModeEnabled ? KaColors.primary : null,
                      onPressed: () {
                        ref.read(settingsProvider.notifier).update(
                              settings.copyWith(
                                adminModeEnabled: !settings.adminModeEnabled,
                              ),
                            );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Config sync
            _SettingsCard(
              title: 'Konfiguration',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'EXPORTIEREN (.JSON)',
                        icon: Icons.upload_rounded,
                        onPressed: () => _exportConfig(context, ref),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SecondaryButton(
                        label: 'IMPORTIEREN',
                        icon: Icons.download_rounded,
                        onPressed: () => _importConfig(context, ref),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Version info
            _VersionCard(),
          ],
        ),
      ),
    );
  }

  Future<void> _exportConfig(BuildContext context, WidgetRef ref) async {
    try {
      final jobs = ref.read(jobsProvider);
      final storage = ref.read(storageServiceProvider);
      final json = storage.exportJobsAsJson(jobs);

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Konfiguration exportieren',
        fileName: 'kinetic_archive_config.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (path != null) {
        await File(path).writeAsString(json);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exportiert nach $path'),
              backgroundColor: KaColors.surfaceContainerHighest,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export fehlgeschlagen: $e')),
        );
      }
    }
  }

  Future<void> _importConfig(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;

      final raw = await File(path).readAsString();
      final storage = ref.read(storageServiceProvider);
      final jobs = storage.importJobsFromJson(raw);
      await ref.read(jobsProvider.notifier).importJobs(jobs);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${jobs.length} Jobs importiert.'),
            backgroundColor: KaColors.surfaceContainerHighest,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import fehlgeschlagen: $e')),
        );
      }
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KaTextStyles.titleSmall),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: KaTextStyles.bodyMedium),
              Text(subtitle, style: KaTextStyles.bodySmall),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _VersionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [KaColors.primary, KaColors.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_rounded, color: KaColors.onPrimary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The Kinetic Archive', style: KaTextStyles.titleSmall),
                Text(
                  '1.0.0 — The Silent Sentinel Build',
                  style: KaTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          SecondaryButton(
            label: 'UPDATES',
            icon: Icons.sync_rounded,
            onPressed: () => _showUpdateHint(context),
          ),
        ],
      ),
    );
  }

  void _showUpdateHint(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KaColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Auto-Update', style: KaTextStyles.titleMedium),
        content: Text(
          'Auto-Update über GitHub Releases ist vorbereitet.\n\n'
          'Sobald du dein Repository hinterlegt hast, '
          'prüft die App beim Start auf neue Releases und bietet den Download an.\n\n'
          'GitHub-Repo noch nicht konfiguriert.',
          style: KaTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: KaTextStyles.labelLarge.copyWith(color: KaColors.primary)),
          ),
        ],
      ),
    );
  }
}
