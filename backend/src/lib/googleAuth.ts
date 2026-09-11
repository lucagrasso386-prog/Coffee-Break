import jwt, { JwtPayload } from "jsonwebtoken";
import jwksClient from "jwks-rsa";

const GOOGLE_ISSUERS: [string, string] = ["https://accounts.google.com", "accounts.google.com"];
const GOOGLE_JWKS_URI = "https://www.googleapis.com/oauth2/v3/certs";

const client = jwksClient({ jwksUri: GOOGLE_JWKS_URI });

function getSigningKey(kid: string): Promise<string> {
  return new Promise((resolve, reject) => {
    client.getSigningKey(kid, (err, key) => {
      if (err || !key) {
        reject(err ?? new Error("No signing key found"));
        return;
      }
      resolve(key.getPublicKey());
    });
  });
}

export interface GoogleIdentity {
  googleUserId: string;
  email?: string;
}

/**
 * Verifies a Google Sign-In id token (JWT) sent by the app after a
 * successful google_sign_in flow, and returns the Google user id. This is
 * the Android-launch counterpart to verifyAppleIdentityToken -- same shape,
 * same "device account can link to a real account" flow (see
 * routes/auth.ts POST /auth/google), just against Google's issuer/keys.
 */
export async function verifyGoogleIdToken(idToken: string): Promise<GoogleIdentity> {
  const decodedHeader = jwt.decode(idToken, { complete: true });
  if (!decodedHeader || typeof decodedHeader === "string" || !decodedHeader.header.kid) {
    throw new Error("Malformed Google id token");
  }

  const publicKey = await getSigningKey(decodedHeader.header.kid);
  const clientId = process.env.GOOGLE_CLIENT_ID;

  const payload = jwt.verify(idToken, publicKey, {
    algorithms: ["RS256"],
    issuer: GOOGLE_ISSUERS,
    audience: clientId,
  }) as JwtPayload;

  if (!payload.sub) {
    throw new Error("Google id token missing subject");
  }

  return {
    googleUserId: payload.sub,
    email: typeof payload.email === "string" ? payload.email : undefined,
  };
}
