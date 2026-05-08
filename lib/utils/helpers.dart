import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateHelper {
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String formatDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);
  static String formatShortDate(DateTime d) => DateFormat('MMM d').format(d);
  static String dayName(DateTime d) => DateFormat('EEE').format(d);

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static int dayOfYear(DateTime d) =>
      d.difference(DateTime(d.year, 1, 1)).inDays;

  static List<DateTime> daysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var c = dateOnly(start);
    final e = dateOnly(end);
    while (!c.isAfter(e)) {
      days.add(c);
      c = c.add(const Duration(days: 1));
    }
    return days;
  }

  static List<DateTime> daysInMonth(int year, int month) {
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    return daysInRange(first, last);
  }
}

class DurationHelper {
  static String format(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  static String formatTimer(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

extension ColorExt on Color {
  Color withFactor(double factor) {
    return Color.fromARGB(
      a.toInt(),
      (r * factor).clamp(0, 255).toInt(),
      (g * factor).clamp(0, 255).toInt(),
      (b * factor).clamp(0, 255).toInt(),
    );
  }
}
