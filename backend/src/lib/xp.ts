export type StarRating = 1 | 2 | 3;

// 04-systemes-progression-et-xp.md
const FIXED_XP_BY_STARS: Record<StarRating, number> = {
  1: 10_000,
  2: 20_000,
  3: 30_000,
};

const MAX_BONUS_XP = 7_750;
const MIN_BONUS_XP = 1_050;
const BONUS_STEP_XP = 2_000;
// Max bonus applies at 3 stars + 6 unused moves remaining; each additional
// move used past that point (i.e. each life fewer remaining) costs one step.
const BONUS_THRESHOLD_MOVES_REMAINING = 6;

/**
 * Bonus decreases linearly by BONUS_STEP_XP per move used beyond the
 * threshold, floored at MIN_BONUS_XP. The spec gives the max/min endpoints
 * and the step, not an exact formula for every intermediate value below the
 * threshold -- MIN_BONUS_XP is treated as a floor rather than assuming the
 * step arithmetic lands on it exactly.
 */
export function computeBonusXP(movesRemaining: number): number {
  const movesUsedBeyondThreshold = Math.max(0, BONUS_THRESHOLD_MOVES_REMAINING - movesRemaining);
  const bonus = MAX_BONUS_XP - movesUsedBeyondThreshold * BONUS_STEP_XP;
  return Math.max(MIN_BONUS_XP, Math.min(MAX_BONUS_XP, bonus));
}

/** Total XP for finishing a level: fixed XP for the star rating + the moves-
 * remaining bonus. This is the same XP that fills the rewards screen's
 * progress bar (13-ecran-recompenses.md) -- there's only one XP total. */
export function computeLevelXP(stars: StarRating, movesRemaining: number): number {
  return FIXED_XP_BY_STARS[stars] + computeBonusXP(movesRemaining);
}
