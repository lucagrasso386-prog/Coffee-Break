# Coffee Break

A match-3 mobile game: iOS app (Swift/SwiftUI + SceneKit for the 3D
progression map) with a Railway-hosted backend (Node/Express + Prisma +
Postgres) for accounts, progression sync, and in-app purchase validation.

Built following the numbered spec files in
`00-instructions-claude-code.md` — each covers one part of the game and is
processed in order.

## Repo layout

```
ios/       — SwiftUI/SceneKit app (see ios/README.md)
backend/   — Express/Prisma API, deployed on Railway (see backend/README.md)
docs/      — setup checklist + privacy policy template
images/    — unmodified final assets provided by the creator, spec by spec
```

## Status

- [x] `01-setup-projet-et-architecture.md` — project scaffold (this repo
      structure, backend API skeleton, iOS app skeleton). Manual account
      setup (Apple Developer, Railway, App Store Connect) is tracked in
      `docs/SETUP.md` — nothing there can be done from a coding session.
- [x] `02-identite-visuelle.md` — name "Coffee Break", app icon, and logo
      wired into the iOS project (see `ios/README.md` for details).
- [x] `03-assets-de-jeu.md` — the 6 matchable elements, 5 boosts, and coin
      currency wired into the iOS project (see `ios/README.md` for details
      on how the two draft sheets were sliced into individual sprites).
- [x] `04-systemes-progression-et-xp.md` — lives (10 max, +1/hour) and the
      level-completion XP formula, implemented server-side as the source of
      truth (`backend/src/lib/lives.ts`, `backend/src/lib/xp.ts`) with a
      client-side mirror for display (`ios/CoffeeBreak/Models/Lives.swift`,
      `XPReward.swift`). Not yet wired to any UI trigger — that's later
      files (`05`, `11`, `12`).
- [x] `05-mecaniques-de-jeu.md` — special pieces, obstacles, and delivery
      objective assets wired in, plus static data models for each (see
      `ios/README.md` for details, including one naming assumption flagged
      for the creator to confirm). Board generation and the match-3 engine
      itself are deferred to `09`/`10`/`11`.
- [ ] `06-pouvoirs-des-bonus.md` onward — not started yet.
