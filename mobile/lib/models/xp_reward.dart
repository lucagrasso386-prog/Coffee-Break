/// 04-systemes-progression-et-xp.md. Mirrors backend/src/lib/xp.ts exactly,
/// for instant client-side preview (e.g. an end-of-level popup once
/// 12-popups-fin-de-niveau.md exists). The server call
/// (ApiClient.completeLevel) is the authoritative source that actually
/// grants the XP.
class XPReward {
  XPReward._();

  static const Map<int, int> _fixedXPByStars = {1: 10000, 2: 20000, 3: 30000};

  static const int _maxBonusXP = 7750;
  static const int _minBonusXP = 1050;
  static const int _bonusStepXP = 2000;
  static const int _bonusThresholdMovesRemaining = 6;

  static int bonusXP(int movesRemaining) {
    final movesLeftBeforeThreshold = _bonusThresholdMovesRemaining - movesRemaining;
    final movesUsedBeyondThreshold = movesLeftBeforeThreshold < 0 ? 0 : movesLeftBeforeThreshold;
    final bonus = _maxBonusXP - movesUsedBeyondThreshold * _bonusStepXP;
    if (bonus < _minBonusXP) return _minBonusXP;
    if (bonus > _maxBonusXP) return _maxBonusXP;
    return bonus;
  }

  /// [stars] must be 1, 2, or 3.
  static int totalXP({required int stars, required int movesRemaining}) {
    return (_fixedXPByStars[stars] ?? 0) + bonusXP(movesRemaining);
  }
}
