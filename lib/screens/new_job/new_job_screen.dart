import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../models/job.dart';
import '../../models/schedule.dart';
import '../../providers/jobs_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/path_picker_field.dart';

class NewJobScreen extends StatelessWidget {
  const NewJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: KaColors.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: _NewJobForm(),
      ),
    );
  }
}

/// Reusable dialog for creating and editing jobs.
class NewJobDialog extends StatelessWidget {
  const NewJobDialog({super.key, this.existingJob});
  final BackupJob? existingJob;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: KaColors.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: _NewJobForm(existingJob: existingJob),
        ),
      ),
    );
  }
}

class _NewJobForm extends ConsumerStatefulWidget {
  const _NewJobForm({this.existingJob});
  final BackupJob? existingJob;

  @override
  ConsumerState<_NewJobForm> createState() => _NewJobFormState();
}

class _NewJobFormState extends ConsumerState<_NewJobForm> {
  final _nameCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _useCompression = false;
  bool _useEncryption = false;
  bool _showPassword = false;
  bool _appendTimestamp = false;
  bool _retentionEnabled = false;
  int _retentionCount = 3;
  ScheduleFrequency _frequency = ScheduleFrequency.manual;
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 3, minute: 0);
  int _hourlyInterval = 1;
  List<int> _weeklyDays = [1];
  int _weeklyInterval = 1;
  int _monthlyDay = 1;
  int _monthlyInterval = 1;
  DateTime? _oneTimeDate;
  bool _runOnce = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final job = widget.existingJob;
    if (job != null) {
      _nameCtrl.text = job.name;
      _sourceCtrl.text = job.sourcePath;
      _destCtrl.text = job.destinationPath;
      _useCompression = job.useCompression;
      _useEncryption = job.useEncryption;
      _appendTimestamp = job.appendTimestamp;
      _retentionEnabled = job.retentionEnabled;
      _retentionCount = job.retentionCount;
      final s = job.schedule;
      if (s != null) {
        _frequency = s.frequency;
        _scheduleTime = TimeOfDay(hour: s.hour, minute: s.minute);
        _hourlyInterval = s.hourlyInterval;
        _weeklyDays = List<int>.from(s.weeklyDays);
        _weeklyInterval = s.weeklyInterval;
        _monthlyDay = s.monthlyDay;
        _monthlyInterval = s.monthlyInterval;
        _oneTimeDate = s.oneTimeDate;
        _runOnce = s.runOnce;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sourceCtrl.dispose();
    _destCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _sourceCtrl.text.trim().isEmpty ||
        _destCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, Quelle und Ziel sind Pflichtfelder.')),
      );
      return;
    }
    setState(() => _saving = true);

    final schedule = _buildSchedule();

    if (widget.existingJob != null) {
      await ref.read(jobsProvider.notifier).updateJob(
            widget.existingJob!.copyWith(
              name: _nameCtrl.text.trim(),
              sourcePath: _sourceCtrl.text.trim(),
              destinationPath: _destCtrl.text.trim(),
              useCompression: _useCompression,
              useEncryption: _useEncryption,
              encryptionPassword: _useEncryption ? _passwordCtrl.text : null,
              appendTimestamp: _appendTimestamp,
              retentionEnabled: _retentionEnabled,
              retentionCount: _retentionCount,
              schedule: schedule,
            ),
          );
    } else {
      await ref.read(jobsProvider.notifier).addJob(
            name: _nameCtrl.text.trim(),
            sourcePath: _sourceCtrl.text.trim(),
            destinationPath: _destCtrl.text.trim(),
            useCompression: _useCompression,
            useEncryption: _useEncryption,
            encryptionPassword: _useEncryption ? _passwordCtrl.text : null,
            appendTimestamp: _appendTimestamp,
            retentionEnabled: _retentionEnabled,
            retentionCount: _retentionCount,
            schedule: schedule,
          );
    }

    if (mounted) {
      if (widget.existingJob != null) {
        Navigator.of(context).pop();
      } else {
        _resetForm();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingJob != null
                ? 'Job aktualisiert.'
                : 'Job zur Warteschlange hinzugefügt.',
          ),
          backgroundColor: KaColors.surfaceContainerHighest,
        ),
      );
    }
    setState(() => _saving = false);
  }

  JobSchedule? _buildSchedule() {
    if (_frequency == ScheduleFrequency.manual) return null;
    return JobSchedule(
      frequency: _frequency,
      hour: _scheduleTime.hour,
      minute: _scheduleTime.minute,
      hourlyInterval: _hourlyInterval,
      weeklyDays: List<int>.from(_weeklyDays),
      weeklyInterval: _weeklyInterval,
      monthlyDay: _monthlyDay,
      monthlyInterval: _monthlyInterval,
      oneTimeDate: _oneTimeDate,
      runOnce: _runOnce,
    );
  }

  void _resetForm() {
    _nameCtrl.clear();
    _sourceCtrl.clear();
    _destCtrl.clear();
    _passwordCtrl.clear();
    setState(() {
      _useCompression = false;
      _useEncryption = false;
      _appendTimestamp = false;
      _retentionEnabled = false;
      _retentionCount = 3;
      _frequency = ScheduleFrequency.manual;
      _hourlyInterval = 1;
      _weeklyDays = [1];
      _weeklyInterval = 1;
      _monthlyDay = 1;
      _monthlyInterval = 1;
      _oneTimeDate = null;
      _runOnce = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingJob != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEdit ? 'Job bearbeiten' : 'Neuer Job',
          style: KaTextStyles.headlineSmall,
        ),
        Text(
          isEdit
              ? 'Einstellungen anpassen'
              : 'Backup konfigurieren und zur Warteschlange hinzufügen.',
          style: KaTextStyles.bodySmall,
        ),
        const SizedBox(height: 28),

        // Name
        _SectionLabel('Job-Name'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nameCtrl,
          style: KaTextStyles.bodyMedium,
          decoration: const InputDecoration(hintText: 'z.B. Dokumente täglich'),
        ),
        const SizedBox(height: 20),

        // Source
        PathPickerField(
          label: 'Quellverzeichnis',
          hint: '/home/user/Dokumente',
          controller: _sourceCtrl,
          buttonLabel: 'BROWSE',
          pickDirectory: true,
          onChanged: (p) => setState(() {}),
        ),
        const SizedBox(height: 20),

        // Destination
        PathPickerField(
          label: 'Zielverzeichnis',
          hint: '/mnt/nas/backups  oder  \\\\Server\\Share',
          controller: _destCtrl,
          buttonLabel: 'CONNECT',
          pickDirectory: true,
          onChanged: (p) => setState(() {}),
        ),
        const SizedBox(height: 24),

        // Options
        _SectionLabel('Optionen'),
        const SizedBox(height: 12),
        _ToggleRow(
          label: '7zip Komprimierung',
          subtitle: 'Erstellt ein .7z Archiv statt einer Kopie',
          value: _useCompression,
          onChanged: (v) => setState(() => _useCompression = v),
        ),
        const SizedBox(height: 12),
        _ToggleRow(
          label: 'Verschlüsselung (AES-256)',
          subtitle: 'Schützt das Archiv mit einem Passwort',
          value: _useEncryption,
          onChanged: (v) => setState(() {
            _useEncryption = v;
            if (!v) _passwordCtrl.clear();
          }),
        ),

        if (_useEncryption) ...[
          const SizedBox(height: 16),
          _SectionLabel('Passwort'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: !_showPassword,
            style: KaTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: '••••••••••••',
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: KaColors.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Naming & Retention
        _SectionLabel('Dateiname & Aufbewahrung'),
        const SizedBox(height: 12),
        _ToggleRow(
          label: 'Datum & Uhrzeit anhängen',
          subtitle: 'z.B. mein_job_2026-03-29_14-32-00.7z',
          value: _appendTimestamp,
          onChanged: (v) => setState(() => _appendTimestamp = v),
        ),
        const SizedBox(height: 12),
        _ToggleRow(
          label: 'Alte Sicherungen automatisch bereinigen',
          subtitle: 'Nur die letzten N Sicherungen dieses Jobs behalten',
          value: _retentionEnabled,
          onChanged: (v) => setState(() => _retentionEnabled = v),
        ),
        if (_retentionEnabled) ...[
          const SizedBox(height: 12),
          _RetentionCountSelector(
            value: _retentionCount,
            onChanged: (v) => setState(() => _retentionCount = v),
          ),
        ],

        const SizedBox(height: 24),

        // Schedule
        _SectionLabel('Zeitplan'),
        const SizedBox(height: 12),
        _ScheduleEditor(
          frequency: _frequency,
          scheduleTime: _scheduleTime,
          hourlyInterval: _hourlyInterval,
          weeklyDays: _weeklyDays,
          weeklyInterval: _weeklyInterval,
          monthlyDay: _monthlyDay,
          monthlyInterval: _monthlyInterval,
          oneTimeDate: _oneTimeDate,
          runOnce: _runOnce,
          onFrequencyChanged: (f) => setState(() => _frequency = f),
          onTimeChanged: (t) => setState(() => _scheduleTime = t),
          onHourlyIntervalChanged: (v) => setState(() => _hourlyInterval = v),
          onWeeklyDaysChanged: (v) => setState(() => _weeklyDays = v),
          onWeeklyIntervalChanged: (v) => setState(() => _weeklyInterval = v),
          onMonthlyDayChanged: (v) => setState(() => _monthlyDay = v),
          onMonthlyIntervalChanged: (v) => setState(() => _monthlyInterval = v),
          onOneTimeDateChanged: (v) => setState(() => _oneTimeDate = v),
          onRunOnceChanged: (v) => setState(() => _runOnce = v),
        ),

        const SizedBox(height: 32),

        GradientButton(
          label: isEdit ? 'SPEICHERN' : 'ZUR WARTESCHLANGE',
          icon: isEdit ? Icons.save_rounded : Icons.add_rounded,
          onPressed: _submit,
          isLoading: _saving,
          width: double.infinity,
        ),

        if (isEdit) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Abbrechen', style: KaTextStyles.labelLarge.copyWith(
                color: KaColors.onSurfaceVariant,
              )),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: KaTextStyles.labelLarge.copyWith(color: KaColors.onSurfaceVariant),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
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
    return Container(
      decoration: BoxDecoration(
        color: KaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
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
      ),
    );
  }
}

class _RetentionCountSelector extends StatelessWidget {
  const _RetentionCountSelector({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Anzahl behalten', style: KaTextStyles.bodyMedium),
                Text(
                  'Sicherungen älter als die letzten $value werden zur Löschung vorgeschlagen',
                  style: KaTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              _CountBtn(
                icon: Icons.remove_rounded,
                onTap: value > 1 ? () => onChanged(value - 1) : null,
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: KaTextStyles.titleMedium.copyWith(color: KaColors.primary),
                ),
              ),
              _CountBtn(
                icon: Icons.add_rounded,
                onTap: value < 99 ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountBtn extends StatelessWidget {
  const _CountBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? KaColors.surfaceContainerHighest
              : KaColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? KaColors.onSurface : KaColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ScheduleEditor extends StatelessWidget {
  const _ScheduleEditor({
    required this.frequency,
    required this.scheduleTime,
    required this.hourlyInterval,
    required this.weeklyDays,
    required this.weeklyInterval,
    required this.monthlyDay,
    required this.monthlyInterval,
    required this.oneTimeDate,
    required this.runOnce,
    required this.onFrequencyChanged,
    required this.onTimeChanged,
    required this.onHourlyIntervalChanged,
    required this.onWeeklyDaysChanged,
    required this.onWeeklyIntervalChanged,
    required this.onMonthlyDayChanged,
    required this.onMonthlyIntervalChanged,
    required this.onOneTimeDateChanged,
    required this.onRunOnceChanged,
  });

  final ScheduleFrequency frequency;
  final TimeOfDay scheduleTime;
  final int hourlyInterval;
  final List<int> weeklyDays;
  final int weeklyInterval;
  final int monthlyDay;
  final int monthlyInterval;
  final DateTime? oneTimeDate;
  final bool runOnce;
  final ValueChanged<ScheduleFrequency> onFrequencyChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<int> onHourlyIntervalChanged;
  final ValueChanged<List<int>> onWeeklyDaysChanged;
  final ValueChanged<int> onWeeklyIntervalChanged;
  final ValueChanged<int> onMonthlyDayChanged;
  final ValueChanged<int> onMonthlyIntervalChanged;
  final ValueChanged<DateTime?> onOneTimeDateChanged;
  final ValueChanged<bool> onRunOnceChanged;

  static const _weekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frequency dropdown
        _DropdownField<ScheduleFrequency>(
          value: frequency,
          items: ScheduleFrequency.values,
          labelOf: (f) => f.label,
          onChanged: onFrequencyChanged,
        ),

        if (frequency == ScheduleFrequency.hourly) ...[
          const SizedBox(height: 12),
          _LabeledRow(
            label: 'Alle … Stunden',
            child: _IntervalStepper(
              value: hourlyInterval,
              min: 1,
              max: 23,
              onChanged: onHourlyIntervalChanged,
            ),
          ),
        ],

        if (frequency == ScheduleFrequency.daily) ...[
          const SizedBox(height: 12),
          _timePicker(context),
        ],

        if (frequency == ScheduleFrequency.weekly) ...[
          const SizedBox(height: 12),
          _timePicker(context),
          const SizedBox(height: 10),
          // Weekday chips
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final day = i + 1;
              final selected = weeklyDays.contains(day);
              return _DayChip(
                label: _weekdayLabels[i],
                selected: selected,
                onTap: () {
                  final days = List<int>.from(weeklyDays);
                  if (selected && days.length > 1) {
                    days.remove(day);
                  } else if (!selected) {
                    days.add(day);
                  }
                  onWeeklyDaysChanged(days);
                },
              );
            }),
          ),
          const SizedBox(height: 10),
          _LabeledRow(
            label: 'Alle … Wochen',
            child: _IntervalStepper(
              value: weeklyInterval,
              min: 1,
              max: 8,
              onChanged: onWeeklyIntervalChanged,
            ),
          ),
        ],

        if (frequency == ScheduleFrequency.monthly) ...[
          const SizedBox(height: 12),
          _timePicker(context),
          const SizedBox(height: 10),
          _LabeledRow(
            label: 'Am Tag …',
            child: _IntervalStepper(
              value: monthlyDay,
              min: 1,
              max: 28,
              onChanged: onMonthlyDayChanged,
            ),
          ),
          const SizedBox(height: 8),
          _LabeledRow(
            label: 'Alle … Monate',
            child: _IntervalStepper(
              value: monthlyInterval,
              min: 1,
              max: 12,
              onChanged: onMonthlyIntervalChanged,
            ),
          ),
        ],

        if (frequency == ScheduleFrequency.oneTime) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: oneTimeDate ?? now.add(const Duration(days: 1)),
                firstDate: now,
                lastDate: DateTime(2100),
                builder: (ctx, child) => _themedPicker(ctx, child!),
              );
              if (date == null) return;
              if (!context.mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(oneTimeDate ?? now),
                builder: (ctx, child) => _themedPicker(ctx, child!),
              );
              if (time != null) {
                onOneTimeDateChanged(DateTime(
                  date.year, date.month, date.day,
                  time.hour, time.minute,
                ));
              }
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: KaColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.event_rounded, color: KaColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    oneTimeDate != null
                        ? '${_pad(oneTimeDate!.day)}.${_pad(oneTimeDate!.month)}.${oneTimeDate!.year}  '
                          '${_pad(oneTimeDate!.hour)}:${_pad(oneTimeDate!.minute)}'
                        : 'Datum & Uhrzeit wählen …',
                    style: KaTextStyles.bodyMedium.copyWith(
                      color: oneTimeDate != null
                          ? KaColors.primary
                          : KaColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Run-once toggle (visible for all non-manual frequencies)
        if (frequency != ScheduleFrequency.manual &&
            frequency != ScheduleFrequency.oneTime) ...[
          const SizedBox(height: 12),
          _ToggleRow(
            label: 'Nur einmal ausführen',
            subtitle: 'Zeitplan wird nach der ersten Sicherung deaktiviert',
            value: runOnce,
            onChanged: onRunOnceChanged,
          ),
        ],
      ],
    );
  }

  Widget _timePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: scheduleTime,
          builder: (ctx, child) => _themedPicker(ctx, child!),
        );
        if (picked != null) onTimeChanged(picked);
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: KaColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, color: KaColors.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              '${_pad(scheduleTime.hour)}:${_pad(scheduleTime.minute)} Uhr',
              style: KaTextStyles.titleMedium.copyWith(color: KaColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themedPicker(BuildContext ctx, Widget child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: Theme.of(ctx).colorScheme.copyWith(
          primary: KaColors.primary,
          surface: KaColors.surfaceContainer,
        ),
      ),
      child: child,
    );
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: KaColors.surfaceContainerHigh,
          style: KaTextStyles.bodyMedium,
          isExpanded: true,
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(labelOf(item)),
          )).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: KaTextStyles.bodyMedium),
        ),
        child,
      ],
    );
  }
}

class _IntervalStepper extends StatelessWidget {
  const _IntervalStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CountBtn(icon: Icons.remove_rounded, onTap: value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: KaTextStyles.titleMedium.copyWith(color: KaColors.primary),
          ),
        ),
        _CountBtn(icon: Icons.add_rounded, onTap: value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: selected
              ? KaColors.primary.withValues(alpha: 0.2)
              : KaColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: KaColors.primary.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: KaTextStyles.labelMedium.copyWith(
            color: selected ? KaColors.primary : KaColors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
