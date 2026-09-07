import Foundation

/// 04-systemes-progression-et-xp.md. The server is authoritative for the
/// actual lives count (see backend/src/lib/lives.ts) -- this mirrors the
/// same constants/formula for client-side display (e.g. a "next life in..."
/// countdown), not as a source of truth.
enum Lives {
    static let max = 10
    static let refillInterval: TimeInterval = 60 * 60 // 1 hour

    /// Time remaining until the next life, given the progress last synced
    /// from the server. Returns 0 if already at (or somehow above) max.
    static func timeUntilNextLife(current: Int, livesUpdatedAt: Date, now: Date = Date()) -> TimeInterval {
        guard current < max else { return 0 }
        let elapsed = now.timeIntervalSince(livesUpdatedAt)
        let remainder = refillInterval - elapsed.truncatingRemainder(dividingBy: refillInterval)
        return elapsed < 0 ? refillInterval : max(0, remainder)
    }
}
