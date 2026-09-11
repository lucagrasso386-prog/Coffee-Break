import { Router } from "express";
import { z } from "zod";
import { prisma } from "../db/prisma";
import { requireAuth, AuthedRequest } from "../middleware/auth";
import { resolveLives, consumeLife } from "../lib/lives";
import { computeLevelXP, StarRating } from "../lib/xp";

export const progressRouter = Router();

/** Fetches progress and applies any lives regen owed since it was last
 * touched, persisting the resolved state. Single source of truth so GET and
 * every life-affecting endpoint agree on "now". */
async function loadResolvedProgress(userId: string) {
  const progress = await prisma.progress.findUniqueOrThrow({ where: { userId } });
  const resolved = resolveLives({ lives: progress.lives, livesUpdatedAt: progress.livesUpdatedAt });
  if (resolved.lives === progress.lives && resolved.livesUpdatedAt.getTime() === progress.livesUpdatedAt.getTime()) {
    return progress;
  }
  return prisma.progress.update({
    where: { userId },
    data: { lives: resolved.lives, livesUpdatedAt: resolved.livesUpdatedAt },
  });
}

progressRouter.get("/", requireAuth, async (req: AuthedRequest, res) => {
  const progress = await loadResolvedProgress(req.userId!);
  res.json({ progress });
});

const syncSchema = z.object({
  unlockedLevel: z.number().int().min(1).optional(),
  xp: z.number().int().min(0).optional(),
  coins: z.number().int().min(0).optional(),
});

progressRouter.put("/", requireAuth, async (req: AuthedRequest, res) => {
  const parsed = syncSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Invalid body", details: parsed.error.flatten() });
    return;
  }

  const progress = await prisma.progress.update({
    where: { userId: req.userId! },
    data: parsed.data,
  });

  res.json({ progress });
});

const completeLevelSchema = z.object({
  stars: z.union([z.literal(1), z.literal(2), z.literal(3)]),
  movesRemaining: z.number().int().min(0),
});

/** Applies the XP for a finished level (04-systemes-progression-et-xp.md).
 * Not yet wired to a level-end popup -- that's 12-popups-fin-de-niveau.md. */
progressRouter.post("/complete-level", requireAuth, async (req: AuthedRequest, res) => {
  const parsed = completeLevelSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Invalid body", details: parsed.error.flatten() });
    return;
  }

  const { stars, movesRemaining } = parsed.data;
  const xpGained = computeLevelXP(stars as StarRating, movesRemaining);

  const progress = await prisma.progress.update({
    where: { userId: req.userId! },
    data: { xp: { increment: xpGained } },
  });

  res.json({ progress, xpGained });
});

/** Spends one life. Not yet wired to a trigger (level start vs. loss isn't
 * defined until later spec files) but usable once one is. */
progressRouter.post("/consume-life", requireAuth, async (req: AuthedRequest, res) => {
  const current = await loadResolvedProgress(req.userId!);
  const resolved = consumeLife({ lives: current.lives, livesUpdatedAt: current.livesUpdatedAt });

  if (current.lives <= 0) {
    res.status(409).json({ error: "No lives remaining" });
    return;
  }

  const progress = await prisma.progress.update({
    where: { userId: req.userId! },
    data: { lives: resolved.lives, livesUpdatedAt: resolved.livesUpdatedAt },
  });

  res.json({ progress });
});
