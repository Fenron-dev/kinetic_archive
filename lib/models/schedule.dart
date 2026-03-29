import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule.freezed.dart';
part 'schedule.g.dart';

enum ScheduleFrequency { manual, hourly, daily, weekly, monthly, oneTime }

extension ScheduleFrequencyX on ScheduleFrequency {
  String get label => switch (this) {
        ScheduleFrequency.manual => 'Manuell',
        ScheduleFrequency.hourly => 'Stündlich',
        ScheduleFrequency.daily => 'Täglich',
        ScheduleFrequency.weekly => 'Wöchentlich',
        ScheduleFrequency.monthly => 'Monatlich',
        ScheduleFrequency.oneTime => 'Einmaliger Termin',
      };
}

@freezed
class JobSchedule with _$JobSchedule {
  const factory JobSchedule({
    required ScheduleFrequency frequency,

    // Time of day (daily, weekly, monthly)
    @Default(3) int hour,
    @Default(0) int minute,

    // Hourly: every N hours
    @Default(1) int hourlyInterval,

    // Weekly: list of weekdays (1=Mon … 7=Sun), every N weeks
    @Default([1]) List<int> weeklyDays,
    @Default(1) int weeklyInterval,

    // Monthly: day of month (1–28), every N months
    @Default(1) int monthlyDay,
    @Default(1) int monthlyInterval,

    // One-time: specific date+time
    DateTime? oneTimeDate,

    // If true: job is disabled after the first successful execution
    @Default(false) bool runOnce,
  }) = _JobSchedule;

  factory JobSchedule.fromJson(Map<String, dynamic> json) =>
      _$JobScheduleFromJson(json);
}

extension JobScheduleX on JobSchedule {
  /// Returns the next scheduled DateTime strictly after [from].
  DateTime nextRunAfter(DateTime from) {
    switch (frequency) {
      case ScheduleFrequency.manual:
        return _never;

      case ScheduleFrequency.hourly:
        var candidate = from.add(Duration(hours: hourlyInterval));
        candidate = DateTime(
          candidate.year, candidate.month, candidate.day,
          candidate.hour, minute,
        );
        if (!candidate.isAfter(from)) {
          candidate = candidate.add(Duration(hours: hourlyInterval));
        }
        return candidate;

      case ScheduleFrequency.daily:
        var candidate = DateTime(from.year, from.month, from.day, hour, minute);
        if (!candidate.isAfter(from)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;

      case ScheduleFrequency.weekly:
        final days = weeklyDays.toSet();
        if (days.isEmpty) return _never;
        // Walk forward day by day until we hit a matching weekday
        var candidate = DateTime(from.year, from.month, from.day, hour, minute);
        if (!candidate.isAfter(from)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        // Max 7 * weeklyInterval days to find next match
        for (var i = 0; i < 7 * weeklyInterval + 7; i++) {
          if (days.contains(candidate.weekday)) {
            // Check interval: week number relative to a fixed epoch
            final weekNum = _isoWeekNumber(candidate);
            if (weekNum % weeklyInterval == 0) return candidate;
          }
          candidate = candidate.add(const Duration(days: 1));
        }
        return _never;

      case ScheduleFrequency.monthly:
        final day = monthlyDay.clamp(1, 28);
        var candidate = DateTime(from.year, from.month, day, hour, minute);
        if (!candidate.isAfter(from)) {
          candidate = DateTime(from.year, from.month + monthlyInterval, day, hour, minute);
        }
        return candidate;

      case ScheduleFrequency.oneTime:
        final dt = oneTimeDate;
        if (dt == null || !dt.isAfter(from)) return _never;
        return dt;
    }
  }

  static final _never = DateTime(9999);

  /// ISO week number (1-based), used for weekly interval calculation.
  static int _isoWeekNumber(DateTime date) {
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final jan4 = DateTime(thursday.year, 1, 4);
    return 1 + ((thursday.difference(jan4).inDays) ~/ 7);
  }
}
