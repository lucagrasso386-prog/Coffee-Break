# Coffee Break — Mobile App (Flutter)

Flutter app targeting **iOS and Android at launch** (the creator wants both
platforms simultaneously, not iOS-first — see the architecture note below).
Client code lives here in `lib/`; the platform folders (`android/`, `ios/`,
...) are **generated, not committed** — same reasoning as the old XcodeGen
setup: this container can't run the Flutter SDK to produce or validate them,
so they're generated from `pubspec.yaml` + the Flutter/Dart version on a real
machine instead.

## Why Flutter (architecture note)

The original plan (`01-setup-projet-et-architecture.md`) was native Swift/
SwiftUI/SceneKit, iOS-only. Once the creator confirmed Android is required
**at launch**, not "someday," three options were on the table:

- **Unity** — cross-platform, but neither side has Unity experience and this
  coding session has no GUI access to Unity's editor (scenes, prefabs,
  animations can't be built or verified here). High risk of getting stuck on
  the non-code half of the work.
- **Two native codebases** (Swift + Kotlin) — no tooling risk, but doubles
  the client work (engine, UI, animations) for every remaining spec file.
- **Flutter** — one Dart codebase for both platforms, fully code-driven (no
  editor GUI required), so it fits this session's constraints the same way
  Swift did. Chosen for that reason.

The 3D progression map (`09-carte-progression.md`, SceneKit in the original
plan) will need a Flutter-compatible 3D approach when that spec file is
reached — likely a `model_viewer_plus`/glTF-based view or a lighter pseudo-3D
treatment. Flagged here so it isn't a surprise later; not resolved yet since
that spec file hasn't been processed.

**Same blind-authoring limitation as before**: this environment has no
Flutter/Dart SDK, so `lib/` code is written carefully but never compiled or
run here, exactly like the Swift code never was. Build and test on a real
machine before shipping.

## Generate the platform projects

```bash
# one-time, on your machine: https://docs.flutter.dev/get-started/install
cd mobile
flutter create --org com.yourcompany --project-name coffee_break .
flutter pub get
flutter run
```

`flutter create .` on an existing `pubspec.yaml` fills in only the missing
platform folders (`android/`, `ios/`, ...) without touching `lib/`,
`pubspec.yaml`, or `assets/`. Re-run `flutter pub get` any time
`pubspec.yaml` changes.

## Before you build

- Replace the placeholder Bundle ID (iOS) / Application ID (Android) —
  `com.yourcompany.coffeebreak` — once real ones exist in Apple Developer and
  Google Play Console. See `../docs/SETUP.md`.
- `lib/models/app_config.dart` points at a placeholder Railway URL. Update it
  once the backend is deployed.
- Sign in with Apple and Sign in with Google both need platform-side setup
  Flutter's CLI doesn't do for you (Apple: capability + entitlement in
  Xcode's Signing & Capabilities; Google: OAuth client IDs registered per
  platform) — see `../docs/SETUP.md`.
- Generate launcher icons for both platforms from the single source image
  declared in `pubspec.yaml` (`flutter_launcher_icons`):
  ```bash
  flutter pub run flutter_launcher_icons
  ```
- Android: add a backup-exclusion rule once `android/` is generated, so
  `DeviceIdentity` (see below) is wiped on uninstall like it is on iOS by
  default — see the note in `lib/models/device_identity.dart`.

## Structure

```
mobile/
  lib/
    main.dart        — app entry point
    networking/       — backend API client
    models/           — config, device identity, DTOs, game data
  assets/              — game art (see below), flat files (no imageset wrappers)
  pubspec.yaml
```

## Visual identity (`02-identite-visuelle.md`)

- **Name**: "Coffee Break" — set as `title` in `lib/main.dart`'s `MaterialApp`
  (this becomes the platform display name once `flutter create` wires
  `CFBundleDisplayName` / Android's app label from it, or set them directly
  in the generated platform files if you want the display name independent
  of the in-app title).
- **App icon**: `assets/icon/icon-1024.png`. The source asset
  (`images/icone-application.jpg` at the repo root, kept unmodified) is
  1206×1288, not square. Per the creator, it was stretched (non-uniform
  scale, not cropped) to exactly 1024×1024 to meet the App Store's icon
  requirement — that's the one deliberate exception to "assets are never
  modified," done because Apple's format leaves no other option. Declared in
  `pubspec.yaml` under `flutter_launcher_icons`, which generates every
  iOS/Android size from this one image — same "provide once, let tooling
  generate every size" approach as the old Xcode single-size app icon
  feature, just cross-platform now.
- **Logo**: `assets/branding/logo-coffee-break.jpg`, reintegrated unmodified
  at its original 738×523. Not used on any screen yet — screens start with
  `08-page-accueil.md`.

Original, untouched source images for every spec file are mirrored under
`/images` at the repo root.

## Game assets (`03-assets-de-jeu.md`)

- `assets/game_elements/` — the 6 matchable elements (cupcake, donut,
  tartelette, croissant, part de gâteau, bretzel), each isolated on a
  transparent background.
- `assets/boosts/` — the 5 boost visuals (café latte, café à emporter, matcha
  latte, canette de soda, jus d'orange), also isolated with transparent
  backgrounds.
- `assets/currency/coin-cafe.jpeg` — the coin, embedded exactly as provided
  (the only one of the three source images marked `VALIDEE` rather than
  `brouillon`, so it wasn't touched).
- `lib/models/game_element.dart`, `boost.dart`, `currency.dart` — enums
  mapping each asset to its file path, for later screens/mechanics to
  reference.

**Note on the source files**: the current sprites are extracted from
`images/elements-final.jpg` and `images/boosts-final.jpg` — final composite
images (6, resp. 5, items on a solid pink backdrop) provided by the creator
to replace the initial extraction from the original draft sheets
(`elements-a-matcher-brouillon.jpeg`, `boosts-brouillon.jpeg`, still kept in
`/images` for reference). Each item was cropped and isolated from the pink
background; pixel content of every item was left untouched.

## Match-3 mechanics assets and data (`05-mecaniques-de-jeu.md`)

- `assets/special_pieces/` — the 3 special pieces (tourbillon, bombe aux
  éclats, and rayée split into its two stripe orientations as separate
  sprites: `special-rayee-verticale` / `-horizontale`).
- `assets/obstacles/` — the 4 difficulty obstacles: vitrine en verre, caramel
  (2 hit states), cookie aux pépites (4 hit states), macaron.
- `assets/delivery_objectives/` — the 2 "livraison" objective objects
  (chantilly, sac de café).
- `lib/models/special_piece.dart`, `obstacle.dart`, `delivery_objective.dart`
  — static data only (asset paths, hit counts, unlock levels, creation/effect
  descriptions as text). No match-3 board engine exists yet to actually
  detect alignments or apply these effects — that's `11-ecran-de-jeu.md`.
- **Not modeled yet, deferred to later spec files**: the actual board/grid
  engine and match detection; level generation (board size/shape progression
  from 7x7 up to 10x50 around level 1000, mandatory shape variety and
  mission-type alternation between consecutive levels, the environment theme
  changing every 10 levels, pre-loading the first 1000 levels) — this
  depends on `09-carte-progression.md`, `10-fiche-mission-niveau.md`, and
  `11-ecran-de-jeu.md`, none of which exist yet.

**Note on rayée's orientation-to-effect mapping**: the spec doesn't say
which stripe orientation clears a row vs. a column, only that a horizontal
or vertical 4-match creates the piece. `SpecialPiece` assigns
vertical-stripes→column-clear and horizontal-stripes→row-clear per the
common match-3 convention (matching this to the sprite most people expect);
flag it if the creator intended the opposite.

**Two corrections from the first pass, per creator review:**

- **Vitrine en verre**: the source photo shows a donut placed inside the
  glass case as an *example* of "an element enclosed in glass" — it's not
  meant to be baked into the obstacle asset itself, since in-game any
  element can be the one trapped inside. `obstacle-vitrine-verre.png` now
  contains only the glass frame, with the donut's silhouette (and a
  generous margin around it) cut out to full transparency, so it can be
  composited over whichever element the level places underneath.
- **Chantilly**: the source photo's soft drop shadow was being kept as if
  it were part of the object. This one was genuinely hard — the shadow
  blends continuously into the cream's own ambient-occlusion shading with
  no clean color boundary between them (verified: no distance-from-background
  threshold, at any value, cleanly separates the two, since the shadow's
  density right at the contact point matches or exceeds the brightness of
  real object surface elsewhere). A first attempt worked around this by
  tapering the reliable upper silhouette down to close off the base without
  reading the ambiguous pixels at all — technically shadow-free, but the
  fabricated base didn't match the real photo and looked wrong. Fixed
  properly using a different, real signal instead of color: the cream's
  surface has visible fold/crease texture (local pixel variance) even where
  pale, while the shadow is a smooth, textureless gradient. Tracing the
  lowest row of genuine texture in each column recovers the object's actual
  scalloped base contour from the real image data, rather than inventing
  it — the current cutout is a true trace, not a reconstruction.

## Accounts (`01-setup-projet-et-architecture.md`)

- `lib/models/device_identity.dart` — device-local account id, wiped on
  uninstall by design (see the Android backup-exclusion note above).
- `lib/networking/api_client.dart` — `authenticateWithDevice`,
  `authenticateWithApple`, `authenticateWithGoogle`. Apple and Google are the
  two real-account options (`sign_in_with_apple` / `google_sign_in`
  packages, declared in `pubspec.yaml`); neither is wired to a UI yet — that
  starts with `08-page-accueil.md`.

Feature screens aren't built yet — those start with `08-page-accueil.md`
onward, per the numbered spec order. Boost powers (`06-pouvoirs-des-bonus.md`)
aren't implemented yet either.
