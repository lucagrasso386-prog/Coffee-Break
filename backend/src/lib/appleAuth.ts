import jwt, { JwtPayload } from "jsonwebtoken";
import jwksClient from "jwks-rsa";

const APPLE_ISSUER = "https://appleid.apple.com";
const APPLE_JWKS_URI = "https://appleid.apple.com/auth/keys";

const client = jwksClient({ jwksUri: APPLE_JWKS_URI });

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

export interface AppleIdentity {
  appleUserId: string;
  email?: string;
}

/**
 * Verifies a "Sign in with Apple" identity token (JWT) sent by the app after
 * a successful ASAuthorizationAppleIDCredential, and returns the Apple user id.
 */
export async function verifyAppleIdentityToken(identityToken: string): Promise<AppleIdentity> {
  const decodedHeader = jwt.decode(identityToken, { complete: true });
  if (!decodedHeader || typeof decodedHeader === "string" || !decodedHeader.header.kid) {
    throw new Error("Malformed Apple identity token");
  }

  const publicKey = await getSigningKey(decodedHeader.header.kid);
  const bundleId = process.env.APPLE_BUNDLE_ID;

  const payload = jwt.verify(identityToken, publicKey, {
    algorithms: ["RS256"],
    issuer: APPLE_ISSUER,
    audience: bundleId,
  }) as JwtPayload;

  if (!payload.sub) {
    throw new Error("Apple identity token missing subject");
  }

  return {
    appleUserId: payload.sub,
    email: typeof payload.email === "string" ? payload.email : undefined,
  };
}
