/// 04-systemes-progression-et-xp.md. The server is authoritative for the
/// actual lives count (see backend/src/lib/lives.ts) -- this mirrors the
/// same constants/formula for client-side display (e.g. a "next life in..."
/// countdown), not as a source of truth.
class Lives {
  Lives._();

  static const int max = 10;
  static const Duration refillInterval = Duration(hours: 1);

  /// Time remaining until the next life, given the progress last synced
  /// from the server. Returns zero if already at (or somehow above) max.
  static Duration timeUntilNextLife({
    required int current,
    required DateTime livesUpdatedAt,
    DateTime? now,
  }) {
    if (current >= max) return Duration.zero;
    final effectiveNow = now ?? DateTime.now();
    final elapsed = effectiveNow.difference(livesUpdatedAt);
    if (elapsed.isNegative) return refillInterval;
    final elapsedMs = elapsed.inMilliseconds;
    final intervalMs = refillInterval.inMilliseconds;
    final remainderMs = intervalMs - (elapsedMs % intervalMs);
    return Duration(milliseconds: remainderMs < 0 ? 0 : remainderMs);
  }
}
