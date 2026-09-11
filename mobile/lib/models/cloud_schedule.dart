/// 09-carte-progression.md's sky clouds: the creator wants the count to
/// alternate daily rather than always showing the max -- "3 MAX, change 1
/// jour sur deux, y'en a deux et l'autre jour 3."
class CloudSchedule {
  CloudSchedule._();

  static const int maxClouds = 3;

  /// Keyed off a continuous day count (days since the epoch) rather than
  /// `DateTime.day`'s calendar-day-of-month, so the alternation doesn't
  /// hiccup at month boundaries (e.g. day 31 then day 1, both odd).
  static int countFor({DateTime? now}) {
    final epochDays = (now ?? DateTime.now()).difference(DateTime(1970, 1, 1)).inDays;
    return epochDays.isEven ? 2 : maxClouds;
  }
}
