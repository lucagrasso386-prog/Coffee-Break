import { Router } from "express";
import { z } from "zod";
import { prisma } from "../db/prisma";
import { issueSessionToken } from "../middleware/auth";
import { verifyAppleIdentityToken } from "../lib/appleAuth";

export const authRouter = Router();

const deviceAuthSchema = z.object({
  deviceId: z.string().min(1),
});

/**
 * Creates or retrieves the device-local account for an install that hasn't
 * connected a real account. This id must come from storage that does NOT
 * survive an uninstall (e.g. UserDefaults, not Keychain) so that
 * reinstalling starts progress over, per 01-setup-projet-et-architecture.md.
 */
authRouter.post("/device", async (req, res) => {
  const parsed = deviceAuthSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Invalid body", details: parsed.error.flatten() });
    return;
  }

  const { deviceId } = parsed.data;

  const user = await prisma.user.upsert({
    where: { deviceId },
    update: {},
    create: { deviceId, progress: { create: {} } },
    include: { progress: true },
  });

  res.json({
    userId: user.id,
    token: issueSessionToken(user.id),
    progress: user.progress,
  });
});

const appleAuthSchema = z.object({
  identityToken: z.string().min(1),
  // Optional: link the currently-signed-in device account to this Apple ID
  // instead of creating/loading a fresh Apple-linked account.
  linkDeviceId: z.string().optional(),
});

/**
 * Sign in with Apple. Finds an existing user by Apple user id, or links a
 * device-local account to Apple, or creates a fresh account.
 */
authRouter.post("/apple", async (req, res) => {
  const parsed = appleAuthSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Invalid body", details: parsed.error.flatten() });
    return;
  }

  const { identityToken, linkDeviceId } = parsed.data;

  let identity;
  try {
    identity = await verifyAppleIdentityToken(identityToken);
  } catch {
    res.status(401).json({ error: "Invalid Apple identity token" });
    return;
  }

  const existing = await prisma.user.findUnique({
    where: { appleUserId: identity.appleUserId },
    include: { progress: true },
  });

  if (existing) {
    res.json({ userId: existing.id, token: issueSessionToken(existing.id), progress: existing.progress });
    return;
  }

  if (linkDeviceId) {
    const linked = await prisma.user.update({
      where: { deviceId: linkDeviceId },
      data: { appleUserId: identity.appleUserId, email: identity.email },
      include: { progress: true },
    });
    res.json({ userId: linked.id, token: issueSessionToken(linked.id), progress: linked.progress });
    return;
  }

  const created = await prisma.user.create({
    data: { appleUserId: identity.appleUserId, email: identity.email, progress: { create: {} } },
    include: { progress: true },
  });
  res.json({ userId: created.id, token: issueSessionToken(created.id), progress: created.progress });
});
