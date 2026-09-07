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
- [ ] `03-assets-de-jeu.md` onward — not started yet.
