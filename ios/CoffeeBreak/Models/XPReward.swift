import Foundation

/// 04-systemes-progression-et-xp.md. Mirrors backend/src/lib/xp.ts exactly,
/// for instant client-side preview (e.g. an end-of-level popup once
/// 12-popups-fin-de-niveau.md exists). The server call
/// (APIClient.completeLevel) is the authoritative source that actually
/// grants the XP.
enum XPReward {
    private static let fixedXPByStars: [Int: Int] = [1: 10_000, 2: 20_000, 3: 30_000]

    private static let maxBonusXP = 7_750
    private static let minBonusXP = 1_050
    private static let bonusStepXP = 2_000
    private static let bonusThresholdMovesRemaining = 6

    static func bonusXP(movesRemaining: Int) -> Int {
        let movesUsedBeyondThreshold = max(0, bonusThresholdMovesRemaining - movesRemaining)
        let bonus = maxBonusXP - movesUsedBeyondThreshold * bonusStepXP
        return max(minBonusXP, min(maxBonusXP, bonus))
    }

    /// - Parameter stars: 1, 2, or 3.
    static func totalXP(stars: Int, movesRemaining: Int) -> Int {
        (fixedXPByStars[stars] ?? 0) + bonusXP(movesRemaining: movesRemaining)
    }
}
