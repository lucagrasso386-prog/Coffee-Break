# Coffee Break

A match-3 mobile game: a Flutter app targeting **iOS and Android at launch**
with a Railway-hosted backend (Node/Express + Prisma + Postgres) for
accounts, progression sync, and in-app purchase validation.

Built following the numbered spec files in
`00-instructions-claude-code.md` — each covers one part of the game and is
processed in order.

## Repo layout

```
mobile/            — Flutter app, iOS + Android (see mobile/README.md)
backend/           — Express/Prisma API, deployed on Railway (see backend/README.md)
docs/              — setup checklist + privacy policy template
images/            — unmodified final assets provided by the creator, spec by spec
.github/workflows/ — iOS build check + TestFlight publish, no Mac needed (see docs/SETUP.md step 3)
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
- [x] `06-pouvoirs-des-bonus.md` — targeting shape and effect description
      for each of the 5 boosts, plus the 5-boost mission-sheet loadout cap,
      as static data (`mobile/lib/models/boost_power.dart`). No new assets;
      actually running the effects is still `11-ecran-de-jeu.md`.
- [x] `07-regles-globales-ui.md` — reusable pieces for the game-wide rules:
      `SpringButton` (press/spring animation), `HapticsService` (the 7 named
      haptic triggers), `SoundService` (stub, no audio assets yet),
      `LoadingTransitionOverlay` + the 8 loading backgrounds (with the
      requested center seam line added), and `NotificationService` (push
      permission request, needs a Firebase project — `docs/SETUP.md` step
      4). See `mobile/README.md` for what's genuinely wired up vs. still
      open (server-side push sending, mainly).
- [x] `08-page-accueil.md` — the home screen (`mobile/lib/screens/home_screen.dart`),
      also the app's boot screen. Background appears first, then the logo
      (from the left) and the "PLAY"/"SE CONNECTER" buttons (from the
      right) slide in together. The background now switches between day,
      golden hour, and night art based on the phone's local time — turns
      out `09`'s day/night cycle applies here too, not just the level map.
      "PLAY" opens the progression map and "SE CONNECTER" opens a
      stand-in screen, since no account screen exists yet — see
      `mobile/README.md` for details, including the logo's détourage.
- [ ] `09-carte-progression.md` — **core in, decor pending**: the level
      map's real 3D-perspective scroll engine (a level's angle on an
      invisible drum projected against the current rotation —
      `mobile/lib/widgets/cylinder_projection.dart`), level button states,
      and HUD are built and wired from "PLAY"
      (`mobile/lib/screens/progression_map_screen.dart`). The HUD is real
      art now (5/5 icons); sky/path/grass have full day/golden/night sets,
      clouds have day/golden (none at night, by design); level buttons are
      real art for day/golden hour (4 colors × unlit/lit) but still the
      placeholder circle at night, since the creator wants night's
      validated glow noticeably brighter than day's and no night button
      art exists yet to show that. The 1-3 star rating above validated
      nodes is real art too, one star asset reused at 3 sizes with a
      layout that adapts to the count. Every node and decor piece casts a
      contact shadow that scales with the same 3D projection, so items
      read as resting on the curved surface rather than pasted on top of
      it. Decor scatter has its first real filler variant (a plumeria
      tree, with a full day/golden/night set) with the landmark pool (the
      Coffee Bar building) and the rest of the filler variety (palm trees,
      hibiscus)
      still pending. Day/night cycle *for the level map itself*, the
      biome swap every 10 levels, and infinite level generation past the
      first 1000 preloaded are still explicitly deferred. See
      `mobile/README.md` for details. `10` onward not started yet.
