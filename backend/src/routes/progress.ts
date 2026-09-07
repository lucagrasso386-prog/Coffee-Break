import { Router } from "express";
import { z } from "zod";
import { prisma } from "../db/prisma";
import { requireAuth, AuthedRequest } from "../middleware/auth";

export const progressRouter = Router();

progressRouter.get("/", requireAuth, async (req: AuthedRequest, res) => {
  const progress = await prisma.progress.findUnique({ where: { userId: req.userId! } });
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
