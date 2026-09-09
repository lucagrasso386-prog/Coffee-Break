# Coffee Break

A match-3 mobile game: a Flutter app targeting **iOS and Android at launch**
with a Railway-hosted backend (Node/Express + Prisma + Postgres) for
accounts, progression sync, and in-app purchase validation.

Built following the numbered spec files in
`00-instructions-claude-code.md` — each covers one part of the game and is
processed in order.

## Repo layout

```
mobile/          — Flutter app, iOS + Android (see mobile/README.md)
backend/         — Express/Prisma API, deployed on Railway (see backend/README.md)
docs/            — setup checklist + privacy policy template
images/          — unmodified final assets provided by the creator, spec by spec
codemagic.yaml   — cloud iOS build + TestFlight publish (no Mac needed, see docs/SETUP.md step 3)
```

**Architecture note**: `01-setup-projet-et-architecture.md` originally
specified native Swift/SwiftUI/SceneKit, iOS-only. That was rebuilt as a
Flutter app once the creator confirmed Android is required at launch, not
later — see `mobile/README.md` for the reasoning and what changed
(accounts gained a Google Sign-In path alongside Apple; the rest of the
architecture — Railway/Express/Prisma backend, device-local + real-account
model, XP/lives formulas — is unchanged, since none of it was iOS-specific).

## Status

- [x] `01-setup-projet-et-architecture.md` — project scaffold (this repo
      structure, backend API skeleton, mobile app skeleton). Rebuilt from
      Swift/iOS-only to Flutter/iOS+Android once Android-at-launch was
      confirmed (see the architecture note above); accounts now support
      Apple **and** Google sign-in (`backend/src/lib/googleAuth.ts`,
      `POST /auth/google`) alongside the device-local fallback. Manual
      account setup (Apple Developer, Google Play Console, Railway, App
      Store Connect) is tracked in `docs/SETUP.md` — nothing there can be
      done from a coding session.
- [x] `02-identite-visuelle.md` — name "Coffee Break", app icon, and logo
      wired into the mobile project (see `mobile/README.md` for details).
- [x] `03-assets-de-jeu.md` — the 6 matchable elements, 5 boosts, and coin
      currency wired into the mobile project (see `mobile/README.md` for
      details on how the two draft sheets were sliced into individual
      sprites).
- [x] `04-systemes-progression-et-xp.md` — lives (10 max, +1/hour) and the
      level-completion XP formula, implemented server-side as the source of
      truth (`backend/src/lib/lives.ts`, `backend/src/lib/xp.ts`) with a
      client-side mirror for display (`mobile/lib/models/lives.dart`,
      `xp_reward.dart`). Not yet wired to any UI trigger — that's later
      files (`05`, `11`, `12`).
- [x] `05-mecaniques-de-jeu.md` — special pieces, obstacles, and delivery
      objective assets wired in, plus static data models for each (see
      `mobile/README.md` for details, including one naming assumption
      flagged for the creator to confirm). Board generation and the match-3
      engine itself are deferred to `09`/`10`/`11`.
- [ ] `06-pouvoirs-des-bonus.md` onward — not started yet.
