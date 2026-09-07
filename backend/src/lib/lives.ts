export const MAX_LIVES = 10;
export const LIFE_REFILL_INTERVAL_MS = 60 * 60 * 1000; // 1 hour, per 04-systemes-progression-et-xp.md

export interface LivesState {
  lives: number;
  livesUpdatedAt: Date;
}

/**
 * Lazily resolves how many lives a player has "now", given the last stored
 * state. Lives regen 1/hour up to MAX_LIVES. livesUpdatedAt only advances by
 * whole refill intervals so partial progress toward the next life survives
 * across calls, until the cap is hit (at which point the clock resets since
 * further waiting is moot).
 */
export function resolveLives(state: LivesState, now: Date = new Date()): LivesState {
  if (state.lives >= MAX_LIVES) {
    return { lives: MAX_LIVES, livesUpdatedAt: now };
  }

  const elapsedMs = now.getTime() - state.livesUpdatedAt.getTime();
  const livesGained = Math.floor(elapsedMs / LIFE_REFILL_INTERVAL_MS);
  if (livesGained <= 0) {
    return state;
  }

  const lives = Math.min(MAX_LIVES, state.lives + livesGained);
  const livesUpdatedAt =
    lives >= MAX_LIVES
      ? now
      : new Date(state.livesUpdatedAt.getTime() + livesGained * LIFE_REFILL_INTERVAL_MS);

  return { lives, livesUpdatedAt };
}

/** Consumes one life (e.g. on level start/loss -- not yet wired to any
 * trigger, since that's defined by later spec files). Never goes below 0.
 * Keeps whatever partial progress toward the next refill had already
 * accrued, rather than restarting the hour on every life lost. */
export function consumeLife(state: LivesState, now: Date = new Date()): LivesState {
  const resolved = resolveLives(state, now);
  return { lives: Math.max(0, resolved.lives - 1), livesUpdatedAt: resolved.livesUpdatedAt };
}
