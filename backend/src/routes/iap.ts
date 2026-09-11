import { Router } from "express";
import { z } from "zod";
import { prisma } from "../db/prisma";
import { requireAuth, AuthedRequest } from "../middleware/auth";
import { verifyTransaction } from "../lib/appStoreServer";

export const iapRouter = Router();

const validateSchema = z.object({
  signedTransactionInfo: z.string().min(1),
});

/**
 * Validates a StoreKit 2 purchase server-side before granting coins /
 * activating a subscription. See lib/appStoreServer.ts for the TODO to wire
 * up real Apple signature verification.
 */
iapRouter.post("/validate-receipt", requireAuth, async (req: AuthedRequest, res) => {
  const parsed = validateSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Invalid body", details: parsed.error.flatten() });
    return;
  }

  let transaction;
  try {
    transaction = await verifyTransaction(parsed.data.signedTransactionInfo);
  } catch (err) {
    res.status(501).json({ error: "Receipt verification not configured", detail: (err as Error).message });
    return;
  }

  const purchase = await prisma.purchase.upsert({
    where: { transactionId: transaction.transactionId },
    update: {},
    create: {
      userId: req.userId!,
      productId: transaction.productId,
      transactionId: transaction.transactionId,
      originalTransactionId: transaction.originalTransactionId,
      environment: transaction.environment,
      purchaseType: transaction.purchaseType,
    },
  });

  // TODO once purchaseType/productId catalog is defined in 14-boutique.md:
  // credit coins to Progress for consumables, or activate the premium tier
  // for subscriptions, based on transaction.productId.

  res.json({ purchase });
});
