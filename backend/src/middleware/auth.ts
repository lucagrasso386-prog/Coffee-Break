import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET;

export interface AuthedRequest extends Request {
  userId?: string;
}

/**
 * Verifies the app-issued session JWT (set after /auth/apple or /auth/device).
 * This is our own session token, not the Apple identity token.
 */
export function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  if (!JWT_SECRET) {
    res.status(500).json({ error: "Server misconfigured: JWT_SECRET not set" });
    return;
  }

  const header = req.headers.authorization;
  const token = header?.startsWith("Bearer ") ? header.slice("Bearer ".length) : undefined;

  if (!token) {
    res.status(401).json({ error: "Missing bearer token" });
    return;
  }

  try {
    const payload = jwt.verify(token, JWT_SECRET) as { sub: string };
    req.userId = payload.sub;
    next();
  } catch {
    res.status(401).json({ error: "Invalid or expired token" });
  }
}

export function issueSessionToken(userId: string): string {
  if (!JWT_SECRET) {
    throw new Error("JWT_SECRET not set");
  }
  return jwt.sign({ sub: userId }, JWT_SECRET, { expiresIn: "30d" });
}
