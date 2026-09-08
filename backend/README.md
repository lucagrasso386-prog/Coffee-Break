# Coffee Break — Backend

Express + TypeScript + Prisma (Postgres) API for the Coffee Break iOS +
Android game: accounts (device-local, Sign in with Apple, or Sign in with
Google), progression sync (unlocked levels, XP, coins), and server-side IAP
receipt validation.

## Local development

```bash
npm install
cp .env.example .env   # fill in DATABASE_URL etc.
npm run prisma:migrate:dev
npm run dev
```

Server runs on `http://localhost:3000` by default. `GET /health` for a
liveness check.

## Endpoints

- `POST /auth/device` — create/load the device-local account for an install
  without a connected account. Body: `{ deviceId }`.
- `POST /auth/apple` — Sign in with Apple. Body: `{ identityToken, linkDeviceId? }`.
- `POST /auth/google` — Sign in with Google (Android launch counterpart to
  `/auth/apple`). Body: `{ idToken, linkDeviceId? }`.
- `GET /progress` — current progress (requires `Authorization: Bearer <token>`).
  Lazily resolves any lives regen owed since the last call (`src/lib/lives.ts`)
  before returning.
- `PUT /progress` — sync progress. Body: any of `{ unlockedLevel, xp, coins }`.
- `POST /progress/complete-level` — applies the XP for a finished level
  (`src/lib/xp.ts`). Body: `{ stars: 1|2|3, movesRemaining }`. Returns the
  updated progress plus `xpGained`. Not called from any screen yet.
- `POST /progress/consume-life` — spends one life. Not wired to a trigger yet
  (level start vs. loss isn't defined until later spec files).
- `POST /iap/validate-receipt` — validate a StoreKit 2 transaction before
  granting its reward. **Not wired to Apple yet** — see
  `src/lib/appStoreServer.ts` for what's left to do.

## Deploying to Railway

1. Create a Railway project, add a Postgres plugin.
2. Add a service pointing at this repo with **root directory** `backend/`.
3. Set the environment variables from `.env.example` (Railway injects
   `DATABASE_URL` automatically from the attached Postgres plugin).
4. Railway will use `railway.json` (Nixpacks build, `npm run start` after
   running Prisma migrations).

## Still open

- Real Apple receipt/transaction verification (`src/lib/appStoreServer.ts`).
- Google Play Billing receipt/transaction verification — `/iap/validate-receipt`
  only checks Apple's StoreKit 2 shape so far; needs an Android counterpart
  once `14-boutique.md` is processed.
- Crediting coins / activating subscriptions after a validated purchase —
  waiting on the product catalog from `14-boutique.md`.
- Wiring `/progress/consume-life` and `/progress/complete-level` to an actual
  trigger (level start/loss, level-end popup) — that's
  `05-mecaniques-de-jeu.md`, `11-ecran-de-jeu.md`, `12-popups-fin-de-niveau.md`.
- Per-level star state, etc. once `05-mecaniques-de-jeu.md` is processed.
