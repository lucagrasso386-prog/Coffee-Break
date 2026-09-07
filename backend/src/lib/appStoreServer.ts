/**
 * Server-side App Store receipt/transaction validation.
 *
 * This is intentionally left as a stub that fails closed: never trust a
 * purchase the client reports without verifying it against Apple first,
 * since that's exactly the "triche" (cheating) vector 01-setup-projet-et-architecture.md
 * calls out.
 *
 * To finish this:
 *   1. `npm install @apple/app-store-server-library` (Apple's official Node library).
 *   2. Generate an App Store Connect API key (In-App Purchase key type) and set
 *      APPLE_ISSUER_ID, APPLE_KEY_ID, APPLE_IAP_PRIVATE_KEY (the .p8 contents) in env.
 *   3. Use the library's SignedDataVerifier to verify the JWS `signedTransactionInfo`
 *      the app receives from StoreKit 2 after a purchase, against Apple's root
 *      certificates (the library documents how to fetch/bundle them).
 *   4. Replace verifyTransaction() below with the real call and remove the
 *      "not configured" guard.
 *
 * Docs: https://developer.apple.com/documentation/appstoreserverapi
 */

export interface VerifiedTransaction {
  transactionId: string;
  originalTransactionId: string;
  productId: string;
  environment: "Sandbox" | "Production";
  purchaseType: "consumable" | "subscription";
}

export async function verifyTransaction(_signedTransactionInfo: string): Promise<VerifiedTransaction> {
  throw new Error(
    "App Store transaction verification is not configured yet. See src/lib/appStoreServer.ts."
  );
}
