/// 09-carte-progression.md: "Cycle jour/nuit dynamique ... basé sur l'heure
/// et le fuseau horaire réels du téléphone." The creator later confirmed
/// this applies to `08-page-accueil.md`'s background too -- three
/// variants delivered so far (day, golden hour, night), one image each,
/// with morning and evening golden hour sharing the same art.
enum DayNightPeriod { day, goldenHour, night }

class DayNightSchedule {
  DayNightSchedule._();

  /// The spec ties this to the phone's real local time, not an
  /// astronomical sunrise/sunset calculation -- these hour boundaries are
  /// a reasonable placeholder split (golden hour ~3h around sunrise and
  /// sunset, à la Animal Crossing) rather than a measured one, since
  /// there's nothing more specific to go on. Easy to retune once someone
  /// can see it change across a real day.
  static DayNightPeriod current({DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 20 || hour < 5) return DayNightPeriod.night;
    if (hour < 8 || hour >= 17) return DayNightPeriod.goldenHour;
    return DayNightPeriod.day;
  }
}
