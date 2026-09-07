# Coffee Break — Backend

Express + TypeScript + Prisma (Postgres) API for the Coffee Break iOS game:
accounts (device-local or Sign in with Apple), progression sync (unlocked
levels, XP, coins), and server-side IAP receipt validation.

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
- `GET /progress` — current progress (requires `Authorization: Bearer <token>`).
- `PUT /progress` — sync progress. Body: any of `{ unlockedLevel, xp, coins }`.
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
- Crediting coins / activating subscriptions after a validated purchase —
  waiting on the product catalog from `14-boutique.md`.
- Lives, per-level star state, etc. once `04-systemes-progression-et-xp.md`
  and `05-mecaniques-de-jeu.md` are processed.
