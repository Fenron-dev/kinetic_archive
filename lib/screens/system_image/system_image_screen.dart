import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/pulse_progress_bar.dart';

final _sysImageProgressProvider = StateProvider<double>((ref) => 0.0);
final _sysImageRunningProvider = StateProvider<bool>((ref) => false);
final _sysImageOutputProvider = StateProvider<String>((ref) => '');

class SystemImageScreen extends ConsumerWidget {
  const SystemImageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWindows = Platform.isWindows;

    return Scaffold(
      backgroundColor: KaColors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: KaColors.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, color: KaColors.tertiary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Erhöhte Rechte erforderlich',
                    style: KaTextStyles.labelSmall.copyWith(color: KaColors.tertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text('System Image', style: KaTextStyles.headlineSmall),
            const SizedBox(height: 4),
            Text(
              isWindows
                  ? 'Erstellt ein VHDX-Laufwerk-Abbild via disk2vhd.'
                  : 'Erstellt ein komprimiertes Laufwerk-Abbild via dd + gzip.',
              style: KaTextStyles.bodyMedium.copyWith(color: KaColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // Main grid
            _SysImageBentoGrid(isWindows: isWindows),
            const SizedBox(height: 24),

            // CTA
            const _SysImageActions(),
          ],
        ),
      ),
    );
  }
}

class _SysImageBentoGrid extends ConsumerWidget {
  const _SysImageBentoGrid({required this.isWindows});
  final bool isWindows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(_sysImageProgressProvider);
    final isRunning = ref.watch(_sysImageRunningProvider);

    return Column(
      children: [
        Row(
          children: [
            // Active session / progress
            Expanded(
              flex: 3,
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Aktive Sitzung', style: KaTextStyles.labelMedium),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isRunning ? KaColors.primary : KaColors.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isRunning) ...[
                      Text(
                        '${(progress * 100).round()}%',
                        style: KaTextStyles.displaySmall.copyWith(color: KaColors.primary),
                      ),
                      const SizedBox(height: 12),
                      PulseProgressBar(value: progress),
                    ] else ...[
                      Text(
                        'Bereit',
                        style: KaTextStyles.titleLarge.copyWith(
                          color: KaColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kein aktiver Vorgang.',
                        style: KaTextStyles.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Disk info
            Expanded(
              flex: 2,
              child: _InfoCard(
                title: 'Format',
                value: isWindows ? 'VHDX' : '.img.gz',
                subtitle: isWindows ? 'Volume Shadow Copy' : 'dd + gzip',
                icon: Icons.storage_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Protocol steps
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: KaColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ausführungsprotokoll', style: KaTextStyles.titleSmall),
              const SizedBox(height: 16),
              ..._steps(isWindows).map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProtocolStep(step: s),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Output log
        Consumer(builder: (context, ref, child) {
          final output = ref.watch(_sysImageOutputProvider);
          if (output.isEmpty) return const SizedBox.shrink();
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KaColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              output,
              style: KaTextStyles.labelSmall.copyWith(
                fontFamily: 'monospace',
                color: KaColors.primary,
              ),
            ),
          );
        }),
      ],
    );
  }

  List<String> _steps(bool isWindows) => isWindows
      ? [
          '1. Erhöhte Rechte anfordern (UAC)',
          '2. Volume Shadow Copy Service starten',
          '3. disk2vhd Snapshot aufnehmen',
          '4. VHDX-Datei am Zielort ablegen',
          '5. Integrität prüfen',
        ]
      : [
          '1. Root-Rechte anfordern (pkexec)',
          '2. Laufwerk / Partition auswählen',
          '3. dd-Abbild erstellen & gzip komprimieren',
          '4. Image am Zielort ablegen',
          '5. MD5-Prüfsumme berechnen',
        ];
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

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
          Text(title, style: KaTextStyles.labelMedium),
          const SizedBox(height: 12),
          Icon(icon, color: KaColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(value, style: KaTextStyles.headlineSmall.copyWith(color: KaColors.primary)),
          const SizedBox(height: 4),
          Text(subtitle, style: KaTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _ProtocolStep extends StatelessWidget {
  const _ProtocolStep({required this.step});
  final String step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: KaColors.tertiary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(step, style: KaTextStyles.bodySmall.copyWith(
            color: KaColors.onSurfaceVariant,
          )),
        ),
      ],
    );
  }
}

class _SysImageActions extends ConsumerWidget {
  const _SysImageActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(_sysImageRunningProvider);

    return Column(
      children: [
        GradientButton(
          label: isRunning ? 'ABBRECHEN' : 'SYSTEM IMAGE ERSTELLEN',
          icon: isRunning ? Icons.stop_rounded : Icons.camera_alt_rounded,
          isLoading: false,
          onPressed: () {
            if (isRunning) {
              ref.read(_sysImageRunningProvider.notifier).state = false;
              ref.read(_sysImageProgressProvider.notifier).state = 0.0;
              ref.read(_sysImageOutputProvider.notifier).state = '';
            } else {
              // TODO: SystemImageService.run()
              ref.read(_sysImageRunningProvider.notifier).state = true;
            }
          },
          width: double.infinity,
        ),
        if (isRunning) ...[
          const SizedBox(height: 8),
          Text(
            'Vorgang läuft — bitte nicht unterbrechen.',
            style: KaTextStyles.labelSmall.copyWith(color: KaColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
