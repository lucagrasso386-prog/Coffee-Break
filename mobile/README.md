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

## Testing on your own iPhone without a Mac

`../.github/workflows/ios-testflight.yml` builds the iOS app on a GitHub
Actions `macos` runner and pushes it straight to TestFlight — see
`../docs/SETUP.md` step 3 for the one-time secrets setup (all under this
repo's own GitHub settings, no third-party account needed).
`ios-build-check.yml` runs an unsigned compile check on every push that
touches `mobile/`, no secrets required, just to catch build breaks early.

Android has no such requirement: `flutter run` over USB from any laptop
works directly, no cloud build needed.

## Generate the platform projects

```bash
# one-time, on your machine: https://docs.flutter.dev/get-started/install
cd mobile
flutter create --org com.lucagiraud --project-name coffee_break .
flutter pub get
flutter run
```

`flutter create .` on an existing `pubspec.yaml` fills in only the missing
platform folders (`android/`, `ios/`, ...) without touching `lib/`,
`pubspec.yaml`, or `assets/`. Re-run `flutter pub get` any time
`pubspec.yaml` changes.

## Before you build

- iOS Bundle ID is registered as `com.lucagiraud.coffeebreak` (Apple
  Developer); the Android Application ID still needs picking once Google
  Play Console setup happens (step 2 in `../docs/SETUP.md`). The
  `--org com.lucagiraud` above matches the iOS side already; keep it for
  Android too unless a different prefix is picked there.
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

**Re-extraction, per creator review**: `element-cupcake-glacage-chocolat`,
`element-tartelette-fraise-chantilly`, `element-donut-glacage-rose`, and
`element-bretzel` (`element-part-gateau-couches` too, proactively, since it
came from the same batch) were re-cut from new, individual full-resolution
photos the creator provided per item (`images/element-*-hd.jpg`), replacing
the versions cropped from the shared `elements-final.jpg` sheet — same fringe
issue as the boosts, now fixed at the source with cleaner photos instead of
just a better cutout algorithm. Two more things worth recording:
- **Donut**: the darker pink drizzle lines coincidentally read as close
  enough to the pink background color that a naive cutout put false holes
  straight through the icing (background showing through the drizzle) while
  correctly leaving the true center hole open. Fixed by only auto-filling
  holes below a size threshold that's comfortably under the real hole's
  size, so the false ones get patched and the true one doesn't.
- **Tartelette**: the first HD photo the creator sent had a soft cast shadow
  under the tart on the pink backdrop -- the same kind of shadow-blends-into-
  background problem chantilly had, and several fixes were tried (edge
  tracing, watershed segmentation) without fully resolving it. The creator
  then sent a second photo of the same tartelette with no shadow, which
  sidesteps the problem entirely; that's the one actually used.

All 5 boosts (`boost-cafe-latte`, `boost-cafe-a-emporter`, `boost-matcha-latte`,
`boost-canette-soda`, `boost-jus-orange`) got the same treatment: re-cut from
individual HD photos (`images/boost-*-hd.jpg`) instead of the shared
`boosts-final.jpg` sheet crops. All five came out clean on the first pass with
the same pipeline used for the game elements -- no shadow, no false holes;
`boost-cafe-latte`'s handle hole was correctly left open, same as before.

`element-croissant` — the 6th and last game element, re-cut from
`images/element-croissant-hd.jpg` the same way; came out clean on the first
pass. Every game element and boost is now sourced from an individual HD
photo rather than the original shared sheets.

**Correction, per creator review**: `boost-cafe-latte`, `boost-cafe-a-emporter`,
`boost-matcha-latte`, and `boost-canette-soda` all showed a thin residual pink
fringe around their edges (JPEG chroma-subsampling bleed from the pink
backdrop, a few pixels deep — the same root cause as the chantilly fringe
under `05-mecaniques-de-jeu.md` below, fixed the same way: erode a few px past
the contaminated band, then a tight 1px feather with background-color
unmixing on the clean boundary). Re-extracting surfaced two more things to
get right, not just copy blindly across all four:
- `boost-cafe-latte`'s cup handle has a real hole (background visible through
  the loop) that a blind "fill every enclosed gap" pass would have plugged
  with solid color -- fixed by only auto-filling small (≤500px) holes, which
  catches antialiasing noise while leaving a real hole like this one alone.
- `boost-canette-soda`'s glossy highlights on the red can are coincidentally
  close to the pink background color at a few spots, which the same
  color-distance segmentation misread as small background gaps *inside* the
  can body -- these aren't real, so (unlike the cup handle) they're exactly
  what that small-hole auto-fill is for.

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
  descriptions as text). The match-3 board engine exists now
  (`11-ecran-de-jeu.md`, `lib/models/game_board.dart`), but it doesn't
  detect these alignment patterns, place obstacles, or run delivery-style
  travel yet — deliberately deferred (see that section below).
- **Still not modeled, deferred further**: level generation (board
  size/shape progression from 7x7 up to 10x50 around level 1000, mandatory
  shape variety and mission-type alternation between consecutive levels,
  the environment theme changing every 10 levels, pre-loading the first
  1000 levels) — no real balancing data exists yet to build this from.

**Note on rayée's orientation-to-effect mapping**: the spec doesn't say
which stripe orientation clears a row vs. a column, only that a horizontal
or vertical 4-match creates the piece. `SpecialPiece` assigns
vertical-stripes→column-clear and horizontal-stripes→row-clear per the
common match-3 convention (matching this to the sprite most people expect);
flag it if the creator intended the opposite.

**Corrections from creator review, across multiple passes:**

- **Vitrine en verre** — pass 1: the source photo shows a donut placed
  inside the glass case as an *example* of "an element enclosed in glass,"
  not meant to be baked into the obstacle asset itself, since in-game any
  element can be the one trapped inside; fixed by cutting the donut's
  silhouette out to full transparency, keeping the rest of the glass frame
  solid. Pass 2 (creator wanted a genuinely glassy look instead of a solid
  frame): `obstacle-vitrine-verre.png` is now just a thin outline tracing
  the case's true outer silhouette (from the real photo edge, not an
  invented line) plus the one real specular highlight streak from the
  source photo's top-left corner — every other original "solid glass"
  pixel, plus the whole interior, is transparent. The boundary between the
  thin frame and the transparent interior is a very large gaussian falloff
  (not a hard edge), and the frame itself sits at ~40% opacity so it reads
  as translucent glass over whatever element/background is composited
  underneath, rather than as an opaque ring.
- **Chantilly** — pass 1: the source photo's soft drop shadow was being
  kept as if it were part of the object. This one was genuinely hard — the
  shadow blends continuously into the cream's own ambient-occlusion shading
  with no clean color boundary between them (no distance-from-background
  threshold, at any value, cleanly separates the two). A first attempt
  tapered the reliable upper silhouette down to close off the base without
  reading the ambiguous pixels at all — technically shadow-free, but the
  fabricated base didn't match the real photo. Pass 2 fixed the base
  properly with a real signal instead of color: the cream's surface has
  visible fold/crease texture (local pixel variance) even where pale, while
  the shadow is a smooth, textureless gradient; tracing the lowest row of
  genuine texture per column recovers the true scalloped base contour from
  real image data instead of inventing it. Pass 3 (creator: shadow still
  visible, edges dirty): the pass-2 texture trace, on its own, still let a
  thin sliver of shadow through in the one region where the fold texture
  signal is weakest (the lower-right flank), and per-column noise in that
  trace produced small jagged notches along the edge. Fixed by combining
  three signals instead of one -- a border-connected flood fill from the
  background (correct almost everywhere except the shadow "shelf" it
  also pulls in), clipped by the texture trace specifically in the base
  region only (leaving the flood fill's own clean silhouette untouched on
  the sides/top, where there's no shadow to begin with) -- with the texture
  cutoff median-smoothed across columns so isolated noisy readings can't
  notch the edge. Pass 4 (creator: a big chunk of the cream itself is now
  missing): the pass-3 border-connected flood fill, while good at excluding
  the shadow, also silently ate into a real but very pale/low-contrast fold
  on the object's left side -- pixels close enough to background-white in
  raw color that the flood fill crossed right through them from the border,
  since color-distance alone can't tell "pale object" from "background"
  there. Replaced the whole silhouette method with Sobel gradient-magnitude
  edge detection instead of color distance: even a very pale fold still has
  a real (if faint) brightness *edge* against the background, so tracing
  that edge (closing small gaps, then filling the closed contour) recovers
  the true full silhouette -- pale lobe included -- while still correctly
  excluding the shadow, since the shadow's own boundary is a smooth gradient
  with no comparable edge to trace. This is now a strictly better signal
  than both the plain color-distance and local-texture approaches tried in
  earlier passes. Pass 5: the creator then supplied a new source photo of
  the same object on a flat magenta backdrop
  (`images/objectif-livraison-chantilly-v2-fondrose.jpg`), which sidesteps
  the white-on-white ambiguity entirely -- extracted via plain color-distance
  thresholding instead, since a saturated, unique background color has a
  clean separation from the pale cream with no shadow-blending problem to
  work around. One real fix needed here: pixels within a few pixels of the
  edge carry JPEG chroma-subsampling bleed from the magenta background
  (visible as a thin magenta fringe if left in), so the mask is eroded a
  few pixels past that contaminated band rather than trying to recover it,
  before a tight 1px feather + background-color unmix on the new, clean
  boundary.

## Boost powers (`06-pouvoirs-des-bonus.md`)

- `lib/models/boost_power.dart` — `BoostTargeting` (how the player picks a
  target for each boost: a column, a single board element, an element
  *type*, no target at all, or the two-step "tap a board element for the
  source type, then tap a destination icon off-board" flow that jus
  d'orange needs) and an `effectDescription` per `Boost` case, as text —
  same static-data-only treatment as `SpecialPiece`/`Obstacle` in
  `05-mecaniques-de-jeu.md`, since actually running any of these five
  effects needs the match-3 board engine, which is still `11-ecran-de-jeu.md`.
- `maxEquippedBoosts = 5` — the mission-sheet loadout cap the spec mentions
  ("max 5 bonus"). Not enforced anywhere yet; there's no mission sheet
  screen or loadout state to enforce it in until `10-fiche-mission-niveau.md`.
- No new assets — this file is pure behavior, reusing the boost sprites
  already wired in `03-assets-de-jeu.md`.

## Global UI rules (`07-regles-globales-ui.md`)

These apply across every future screen, not to one feature -- some are
buildable now as reusable pieces, some are just documented rules to follow
once there are screens to apply them to.

- **Screen adaptability**: no fixed-size canvas anywhere, ever -- build
  every screen with `MediaQuery`/`LayoutBuilder`/`Flexible`/`Expanded`/
  `SafeArea` so it fills the real device exactly, no black bars or empty
  space. Reference/test device is the iPhone 17 Pro, but nothing should be
  hardcoded to its exact dimensions. This is a rule for `08-page-accueil.md`
  onward, not something with its own file to point to.
- `lib/widgets/spring_button.dart` — `SpringButton`, a press-and-spring-back
  wrapper every tappable control in the game should use ("tous les boutons
  du jeu, sans exception"). Scales down on press, overshoots slightly past
  full size on release before settling -- a real elastic curve, not just a
  linear snap-back.
- `lib/services/haptics_service.dart` — `HapticsService`, one named method
  per haptic trigger the spec lists (match success, special piece effect,
  the moves-to-stars animation, releasing a "Jouer" button, releasing a
  level "buzzer", the star reveal, tapping the nav bar). Built on Flutter's
  own `HapticFeedback`, so no extra platform setup needed.
- `lib/services/sound_service.dart` — `SoundService.play(SoundEffect)`, a
  stub (logs in debug, otherwise no-op) for the "every button and animation
  needs a sound" rule. No audio files exist yet and no music is planned for
  now (per the same spec file) -- this exists so call sites can be wired up
  ahead of the actual assets, and only the stub's body needs to change once
  they exist.
- `lib/widgets/loading_transition_overlay.dart` — `LoadingTransitionOverlay`,
  the inter-screen loading animation (splits into top/bottom halves that
  slide together from off-screen to appear, and back apart to dismiss),
  capped at 2 seconds on screen total. Explicitly **not** for the very
  first loading screen at app launch (`08-page-accueil.md`'s job).
  `assets/loading_backgrounds/` holds the 8 background variants -- each
  one had a thin darker horizontal line added at its vertical center
  (sampled from that image's own background color, not an invented tint)
  since the source photos didn't have one; the spec's own dev note asks
  for this so the panel reads as hinged/opening in its middle rather than
  as one flat image cut in half. Not wired into any navigation yet since
  there's no screen to navigate *to* until `08-page-accueil.md` onward
  exist.
- `lib/services/notification_service.dart` — `NotificationService`, push
  permission request + token retrieval via `firebase_messaging`. Needs a
  real Firebase project (`google-services.json` / `GoogleService-Info.plist`)
  that doesn't exist yet, see `docs/SETUP.md` step 4 -- `Firebase.initializeApp()`
  is deliberately not called from `main.dart` yet, since doing so without
  those config files would crash the app on startup. Sending an actual
  notification (e.g. when lives refill) needs the Firebase Admin SDK
  server-side plus somewhere to store each user's token, neither of which
  exist -- flagged as open work, not built.

## Accounts (`01-setup-projet-et-architecture.md`)

- `lib/models/device_identity.dart` — device-local account id, wiped on
  uninstall by design (see the Android backup-exclusion note above).
- `lib/networking/api_client.dart` — `authenticateWithDevice`,
  `authenticateWithApple`, `authenticateWithGoogle`. Apple and Google are the
  two real-account options (`sign_in_with_apple` / `google_sign_in`
  packages, declared in `pubspec.yaml`); neither is wired to a UI yet — that
  starts with `08-page-accueil.md`.

## Home screen (`08-page-accueil.md`)

Status: **VALIDÉ**. The spec's appear sequence — background alone first
while the app loads, then the logo sliding in from the left at the same
time the buttons slide in from the right — needed the background, logo,
and buttons as independent layers, but the only asset provided at first
was one flat merged mockup (`images/page-accueil.jpg`). Extracting a
"clean" background from it would have meant inventing pixels behind the
logo/buttons that aren't in the real photo — against the standing "never
invent" rule — so the screen waited until the creator supplied the
background separately (`images/decor-page-accueil.jpg`, mirrored
unmodified as always; confirmed: the decorative pastries scattered in the
grass are part of that fixed background image, not recomposited from the
individual `assets/game_elements/` sprites).

- `assets/home/home_background_day.jpg`, `_golden.jpg`, `_night.jpg` — the
  background, unmodified, in the three lighting variants the creator has
  sent so far. Turns out `09-carte-progression.md`'s day/night cycle
  ("basé sur l'heure et le fuseau horaire réels du téléphone") applies
  here too, not just the level map -- confirmed by the creator sending a
  golden-hour and a night version of this same background unprompted.
  `lib/models/day_night_period.dart` (`DayNightSchedule.current()`) maps
  the phone's local hour to one of the three (morning and evening golden
  hour share the same art, per what was actually delivered); picked once
  in `initState`, not re-picked on every rebuild. The hour boundaries are
  a reasoned placeholder split, not a measured one -- there's no
  astronomical sunrise/sunset input, per the spec, just local time.
- `assets/branding/logo_coffee_break.png` — the "Coffee Break" logo (heart,
  wood sign, leaf, checkered ribbon), cut from `logo-coffee-break.jpg`.
  Much simpler détourage than the buttons since the source sits on a flat
  gradient sky rather than a textured, shadow-casting one -- the only
  snag was the small checkered ribbon under "Break", whose blue squares
  are close enough to sky-blue that a first pass classified them as
  background too (a jagged bite out of the ribbon). Fixed by tightening
  the blue/non-blue rule from a plain "blue-ish" threshold to how far blue
  the pixel actually is (`B - R`): true sky sits far higher on that scale
  than the ribbon's muted plaid, so a stricter cutoff keeps the whole
  ribbon while still separating the logo cleanly from the sky everywhere
  else.
- `lib/screens/home_screen.dart` — `HomeScreen`. Background renders
  immediately (the "loads first" beat happens for free -- Flutter builds
  it in frame one while the logo/buttons start translated off-screen);
  after a short delay, one `AnimationController` drives both the logo (from
  the left) and the button column (from the right) into place together
  via `SlideTransition`, easing out. Every position/size is a fraction of
  the screen's own width/height (measured off the original mockup, which
  is why the layered background needed to keep the same crop/aspect ratio
  the mockup had) rather than a fixed pixel value, per the
  screen-adaptability rule. "PLAY" establishes the device-local account
  session (`ApiClient.authenticateWithDevice()`, best-effort -- offline/
  no-backend is fine) then opens the progression map
  (`09-carte-progression.md`); "SE CONNECTER" navigates to a stand-in
  screen, since no account/sign-in screen exists yet -- see below for the
  progression map, and `widgets/coming_soon_screen.dart` for the stand-in.
- `lib/main.dart` — now boots straight into `HomeScreen`.

Earlier groundwork, still true:

- `assets/ui/button_play.png`, `assets/ui/button_se_connecter.png` — the
  "PLAY" and "SE CONNECTER" pill buttons, cropped directly out of the
  mockup at their native resolution (confirmed: crop from the mockup rather
  than rebuild in code, to keep the exact painted bevel/highlight/gradient).
  The crop was harder than a normal détourage because the pills sit on the
  dirt path, not a flat background: both buttons cast a soft shadow onto
  the path in the gap between them, a bush casts another shadow next to
  "se connecter", and both shadows share enough of the pill's own
  pink/salmon hue that every plain color-distance threshold tried pulled
  some of one or the other in as part of the shape -- as a fringe, as a
  jagged notch, or (worst case) as a bridge fusing the two buttons into one
  blob. Went through a few fixes chasing this pixel-by-pixel (cropping the
  source at the row where color snaps back to full brightness rather than a
  fixed margin, deeper erosion plus unmixing the background out of the
  remaining edge band, blurring the silhouette's signed distance to smooth
  a stray notch) before recognizing these are vector-designed stadium
  buttons -- a perfect capsule shape (rounded-rect corner radius equal to
  half the height) -- so the outer silhouette doesn't need to be *found* at
  all: it's two straight color transitions and a radius. Measured the true
  edge on each side as the point of steepest color change (reliably
  distinct from the ambient shadow's much slower gradient) at several
  points along each side, fit the exact capsule from those, and used it
  directly as the mask -- no color threshold touches the outer boundary
  anymore. The interior (all shading, the highlight, the text, the
  button's own dark bevel border) is still exactly the photographed
  pixels; only the outer edge is reconstructed as the precise geometric
  shape the button was always drawn as, extrapolated a few px past a
  safely-interior sample so the edge color has no background blended into
  it at all.
- `lib/widgets/home_action_buttons.dart` — `PlayButton` and `SignInButton`,
  each just the cropped art wrapped in `SpringButton` for the required
  press/spring feedback.

## Progression map (`09-carte-progression.md`) — core in, decor pending

Status: **concept validé**. This is the level map: a zigzagging path of
round level buttons scrolling over a curved surface. The spec's own
technical section assumed native iOS (SceneKit, a cylinder mesh) --
obsolete since the Flutter pivot -- and offers a simpler 2D/parallax
fallback for V1, but the creator asked for the real 3D curvature now
rather than the fallback. Built without any 3D engine dependency: each
level (and eventually each decor piece) sits at a fixed angle on an
invisible drum whose axis points at the camera; scrolling changes a
`rotation` value, and projecting angle-against-rotation each frame
(`lib/widgets/cylinder_projection.dart`, `CylinderProjection.project`)
gives that item's screen position, scale, and opacity -- genuine
perspective math, applied to ordinary `Positioned`/`Transform` widgets.
Fling gestures hand off to a `FrictionSimulation` for momentum. The exact
curve (how tight, how fast) is tuned by reasoned constants, not by eye --
this environment has no way to run the app on a device, so expect to
adjust `CylinderProjection`'s `radius`/`focalLength` once someone can
actually watch it scroll.

Per the creator's explicit split, three sizable systems are deferred
entirely (flagged in code comments, not attempted): the day/night cycle,
the biome change every 10 levels, and true infinite level generation.
`LevelMapGenerator` preloads a static 1000-level window (matching the
spec's "1000 premiers niveaux pré-chargés"); the other 9000 of the "10 000
accessible at launch" aren't generated yet.

Most real art for the level buttons still doesn't exist -- the two
mockups are one merged composite each (background + path + buttons + HUD
baked together), and the creator is sending individual clean elements
instead of having them cropped out of the composites. Clouds, palm trees,
hibiscus, plumeria, Coffee Bar, and level buttons are all still
placeholders: plain colored circles (with a glow + gold stars for
validated levels, matte for not) standing in for the metallic level
buttons, nothing at all yet for the rest.
`lib/screens/progression_map_screen.dart` is built so re-skinning is
mostly swapping what each placeholder paints, not restructuring the
scroll logic itself. Since biome switching is deferred (see above), the
transition bridge asset isn't needed for this pass either. No horizon/hill
shape exists yet either, so the ground currently starts at a fixed 35%
down the screen -- a placeholder split, not a measured one.

The sand path is real art now, in all three lighting variants
(day/golden-hour/night). `DayNightSchedule.current()` (the same
phone-local-time mapping the home screen uses) picks which one to load,
confirming this piece follows the day/night cycle too, not just the home
screen background -- first full day/night set for any piece of level-map
decor. `_PathPainter` strokes the path through the node centers
using the actual texture as an `ImageShader`, tiled well below its native
1024px size so it reads as a repeating grain rather than one giant blotch
stretched along the path, and with `TileMode.mirror` (not `.repeated`) so
adjacent tiles always match at the seam -- mirroring is seamless by
construction even though the source photo itself isn't a tileable
pattern. Loaded once asynchronously in `initState` via
`instantiateImageCodec` (a `CustomPainter` needs a ready `ui.Image`, it
can't await one mid-`paint()`); falls back to the old flat tan color for
the one frame or so before it's decoded. The tiling frequency is reasoned
against the path's ~48px stroke width, not verified on a device -- worth
a look once someone can actually see it scroll.

The grass ground is real art too now, in all three lighting variants --
same as the sand path, the second piece of level-map decor with a
complete day/night set. The creator's source photo is one green field with
several tufts already scattered across it -- tiling that whole image
would repeat the exact same tuft cluster in an obvious grid, so it's
split in two: a tuft-free strip cropped from the same photo, tiled
seamlessly as the continuous base (same `ImageShader` + `TileMode.mirror`
trick as the path), and the tufts stamped sparsely on top by
`_GrassPainter` at scattered, jittered positions (random offset, scale,
rotation per cell, seeded per-cell so the layout is stable across
rebuilds) -- directly per the creator's own instruction: "des fois tu
mets l'image vert, des fois tu mets l'image vert avec la touffe d'herbe."
The tuft image itself is pre-feathered to fully transparent at its own
edges (a smoothstep radial falloff, done once in Python before saving
each asset) so each stamp blends into the base with no visible square
border, regardless of whether the two greens match exactly at that
point. Same crop coordinates (top strip) worked for all three variants
since the golden-hour and night photos share the day one's exact
composition, just a different color grade each.

The sky itself is real art too, in all three lighting variants -- unlike
the path and the grass, it's a single full-bleed `Image.asset` rather
than a tiled `ImageShader` (nothing to repeat; it just fills the screen
once), picked the same way `HomeScreen` picks its own background: once
per screen instance in `initState` via `DayNightSchedule.current()`, not
re-evaluated on every rebuild. The night sky has a persistent aurora
borealis baked into the art itself (the creator's own touch, beyond what
`09-carte-progression.md`'s "poussière d'étoiles visible" describes) --
just part of that one image, nothing extra to wire up for it. It first
came up when asking about the
sky: the creator mentioned the day/night cycle applies to
`08-page-accueil.md`'s background too, not just this screen -- already
wired there (see that section above). Three pieces of level-map decor
(sky, sand path, grass) now have complete day/night sets; the rest
(clouds, palm trees, hibiscus, plumeria, Coffee Bar) will need the same
treatment once their art exists, per the creator.

On top of the sky art itself, the creator sent a moon and two different
star shapes to scatter across the night sky specifically -- "apparaît
disparaît, aléatoirement dans le ciel en tout petit plein avec une
lueurs autour." `lib/widgets/twinkle_field.dart` (`TwinkleField`) places
several of each (cycled across a fixed, seeded scatter so positions and
timing stay stable across rebuilds without lining up in an obvious
pattern) inside `ProgressionMapScreen`, confined to the sky region and
gated to `DayNightPeriod.night` only -- doesn't make sense against a
bright day or golden-hour sky. Each one runs its own independent
fade-in/hold/fade-out/hold-off loop (`TweenSequence`, randomized period
and start delay) so they don't all pulse in sync, with a soft glow drawn
as the same sprite tinted flat white and blurred behind the crisp one --
matches the sprite's own silhouette rather than a generic circular
bloom. The 3 sprites came in on a bright chroma-key background (pink,
then the creator sent a cleaner purple one to actually use) -- a
straightforward cutout by comparison to earlier ones in this file, no
edge-hue issues this time.

Clouds followed, now in day and golden-hour variants (two shapes each,
cut from pink then cyan chroma-key sources, per the creator "c'est
pareil" for golden hour). The creator later sent a replacement pair for
the day shapes ("refait le jour avec eux") -- same pink chroma-key, but
this time the cutout showed a thin magenta fringe along the edge: the
source's anti-aliased boundary blends real cloud color with the pink
background, so a pixel just inside the silhouette isn't pure cloud color
even after erosion picks a clean interior seed. Fixed with edge color
decontamination -- for any pixel with partial alpha, unmix it as
`(pixel - (1-alpha)*background) / alpha` before writing it out, instead
of keeping the source pixel's raw (background-tinted) color. Cheap
enough to apply to every cutout going forward if the same fringe shows
up again. Per the creator ("3 MAX
change 1 jour sur deux y'en a deux et l'autre jour 3"), the count
alternates daily between 2 and 3 rather than always showing the max --
`lib/models/cloud_schedule.dart` (`CloudSchedule.countFor()`) keys this
off a continuous day count (days since the epoch, not `DateTime.day`'s
calendar-day-of-month) so the alternation doesn't hiccup at month
boundaries. Unlike the twinkle field, clouds sit at 3 fixed positions
(`_cloudSlots` in `progression_map_screen.dart`) rather than a random
scatter -- with only 2-3 on screen, a deliberate placement reads better
than a seeded-random one; today's count just picks how many of those
fixed slots render, cycling through the period's 2 shapes by index.
Night gets no clouds at all -- per the creator ("pas de nuage la nuit"),
`_cloudCount` is forced to 0 for that period rather than falling back to
the day art like the sand path and grass did before their own night
variants arrived; the twinkle field is the night sky's only decor.

The HUD row, on the other hand, is fully real art now (`_HudButton`
still supports a Material `icon` placeholder as a fallback, but nothing
uses it here anymore): the coin and rewards cup turned out to already
exist elsewhere (`Currency.coinCafe` from `03-assets-de-jeu.md`, and the
"café latte" boost art, confirmed by the creator to be the same cup as
the rewards icon) and got reused as-is; the heart, compass, and shop came
as individual renders on a flat green background (`assets/hud/`). That
green cutout turned up a variant of the same lesson as the buttons in
`08-page-accueil.md`: these renders have a soft white-to-background glow
around every edge, and a nearest-neighbor interior-color sampler picking
its seed by raw distance from the exact background color can still land
on a pale, glow-blended pixel that reads as green by hue even though it's
numerically far from the background color (mostly by being much
lighter). Fixed by testing the seed for green *hue* (green channel
clearly above both red and blue) instead of distance from one specific
green value. Also hit the same "real hole vs. false hole" question as the
donut/café-latte sprites back in `03-assets-de-jeu.md`: the compass has a
genuine hole (its hanging ring), so hole-filling only applies below a
size threshold, same fix as before.

Level buttons are real art too now, for day and golden hour (the
creator: "jour et golden hour c'est les meme pour ca" -- one asset set
covers both). 4 colors (blue, purple, pink, and a teal one that maps to
`LevelButtonColor.lightBlue`) times 2 states (unlit/not-validated, lit/
validated-and-glowing), all 8 cut from two green chroma-key composites
(one row of 4 buttons unlit, the same row lit). `_LevelNode` in
`progression_map_screen.dart` picks the lit or unlit asset by
`node.validated`, sized wider than the old placeholder's plain circle
since the real bezel extends past it, with the level number drawn over
it in a `Stack` (given a text shadow now, since it sits on photographic
art rather than a flat color). Night keeps the old placeholder circle
for now rather than reusing this day set: the creator was explicit that
night's validated glow needs to read as noticeably brighter than day's,
so silently reusing the day art (the fallback every other decor layer
used before its own night variant arrived) would misrepresent that once
real night art lands -- better an honest placeholder than a wrong
"final" look.

This cutout hit two new failure modes the others hadn't. First: unlike a
flat render, these buttons have a shiny metal bezel that's genuinely
reflective in the source photo, so it picked up green spill from the
chroma-key background baked into fully-opaque interior pixels (not just
a soft edge blend at the alpha boundary, like every earlier cutout's
issue). Fixed with a despill pass: any pixel where green measurably
exceeds the red/blue midpoint gets pulled down to that midpoint,
applied to blue, purple, and pink (safe, since none of those are ever
meant to look green) and skipped for the teal button, since its whole
point is being green-dominant.

Second, worse one -- caught by the creator after the first push ("ya un
probleme avec le violet et le vert en haut"): the *lit* renders have a
real soft glow bleeding gradually into the green backdrop over ~20-25px
above each button, not a crisp cutout edge (confirmed by sampling a
vertical profile through the purple button: distance from pure
background climbed smoothly over about 25 rows before the solid bezel
started). The original binary-threshold-plus-narrow-erosion approach
(built for crisp-edged sprites, reused as-is here) misread most of that
gradual band as fully-opaque "core" and baked in the half-background
color -- which then either showed through as a wrong hue outright, or,
on top of that, got its green forced flat by the *first* fix's
unconditional despill, turning a soft green glow into a false gray-blue
band. Fixed by computing alpha directly from color distance to the
background (a smoothstep between two distance thresholds) instead of a
binary mask -- this reproduces the render's actual gradual falloff
rather than fighting it -- and by scaling despill strength with that
same alpha so it can no longer flatten a mostly-background pixel into a
wrong color. Worth remembering for any future glowing/bloomed cutout in
this file: a soft light effect painted into a chroma-key composite
needs alpha derived from the real color gradient, not a hard silhouette
with a thin feather bolted on.

The star rating above validated nodes is real art now too
(`assets/progression_map/star.png`). First attempt was waved off before
any cutout work started: the creator's source image carried a faint
"pngtree" watermark baked into the pixels (a stock-clipart tell), so it
got flagged and set aside rather than used -- shipping a watermarked
stock asset isn't "detourage" of the creator's own material, and the
watermark would've been small-but-present in the final art. The
replacement source was clean. Only one star got cut, not three --
despite the reference image showing three (a small one, a big one, a
small one), they're the same star at 3 scales, not 3 different
designs, so `_StarsRow` in `progression_map_screen.dart` reuses the one
asset at different sizes instead. Per the creator ("la place s'adapte
en fonction du nombre gagne"), the *layout* changes with the star
count rather than just hiding unearned slots: 1 star centers alone, 2
sit evenly side by side, and 3 uses the classic bigger-and-raised
center star from the reference image rather than 3 even stars in a
row. Cutout-wise this one was easy by comparison to the buttons: a
flat, solid coral background with a crisp (2-3px) edge, no gradual
glow to worry about and no spill (gold's own red-heavy channel makes a
red-background despill unsafe to apply anyway, so it's skipped here).

The creator is planning to send more decor variety than just one of each
piece (several palm trees, several flower clusters, ...), specifically so
the path doesn't read as one motif copy-pasted down its whole length --
placement is on me, not a fixed spot per piece. `lib/models/decor_variant.dart`
+ `lib/widgets/decor_scatter.dart` (`DecorScatter`) scatter a *pool* of
variants along the path: every candidate slot along the drum
independently rolls, seeded by its own index, whether anything sits there
and which pool variant -- deterministic (stable across rebuilds, no
re-rolling every frame) but not a repeating pattern, since neighboring
slots roll independently. A separate, denser "landmark" placement (no
roll, just fixed spacing) is for waypoints like the Coffee Bar building,
which should read as a fixed marker rather than scattered filler. Decor
pieces project through the same `CylinderProjection` as level nodes and
get depth-sorted into the same draw order, so a close decor piece
correctly overlaps a farther level button (or a farther decor piece) and
vice versa. The filler pool has its first real variant now (see below);
the landmark pool (the Coffee Bar building) is still empty -- registering
a `DecorVariant` per asset once the creator sends them is the only
wiring left; nothing else about the scatter or the scroll needs to
change.

First filler variant in is a plumeria tree ("frangipanier"), now with
a complete day/golden-hour/night set. Unlike the level buttons, which
reuse one asset set as-is for day and golden hour, the creator sent a
genuinely distinct render per period for this piece -- same pose every
time, but each on its own color-graded background (day's magenta reads
~(212,14,155), golden's the same hue but warmer at ~(242,42,148),
night's a cooler purple at ~(133,0,141)) -- so all three are separate
cutouts rather than any period reusing another's asset.
`assets/progression_map/frangipanier_{day,golden,night}.png`,
registered in their own `_fillerDay`/`_fillerGolden`/`_fillerNight`
lists. `_decorScatter` moved from a `static const` to a `late final`
set in `initState` so its filler pool can be picked per `_period`, the
same way `_cloudAssets` already was.

This cutout's background (flat magenta/purple, crisp edges) posed no
real challenge on its own, but its subject did, in two different ways.
First: a full tree canopy has several genuine gaps between overlapping
leaves where the background shows through, not just noise. The usual
size-gated hole-fill (fill small holes, leave large ones open) still
applies, but the size cutoff needed rethinking for this image
specifically -- checking the actual hole sizes first showed every true
noise artifact here was a single stray pixel, while the two real gaps
in the canopy ran into the thousands of pixels, so the fill threshold
got set far tighter (80px) than the compass-ring-style cutouts that
motivated the technique originally. Worth checking per image rather
than assuming the same threshold always applies -- a leafy silhouette
and a metal ring don't fail the same way.

Second, a subtler one that shipped unnoticed in the first version of
all three cutouts, until a zoomed-in look at the night render's petal
edges (prompted by nothing more than double-checking before calling it
done) caught a thin but real magenta/purple fringe tracing every
petal and leaf boundary -- present in the already-pushed day and
golden versions too once checked, just easier to miss against their
own warmer palettes. Root cause: this file's usual edge alpha (a
smoothstep between two fixed color-distance thresholds, tuned once
against saturated button/star colors) assumes every material reaches
"fully opaque" around the same raw color-distance from the background.
That's false for a pale white petal on a saturated magenta backdrop --
white sits ~264 color-distance units from that background at true full
opacity, while the tree's dark trunk brown sits only ~140-160 away even
at its own true full opacity. One fixed HI threshold can't be correct
for both: calibrated low enough for the trunk, it reads a petal edge as
"fully opaque" at barely 40% real coverage, baking in a visible
half-background color. Fixed by dropping the fixed-threshold model
entirely in favor of a local one: erode the already-reliable silhouette
shape (not a color cutoff) to get a safely-interior "core", then for
every edge pixel find its *nearest* core pixel and use that pixel's own
color as the local fully-opaque reference -- solving alpha by
projecting the edge pixel's offset from the background onto that local
background-to-foreground axis, instead of comparing against one global
constant. Adapts per-region automatically (dark trunk and pale petal
each get their own correct reference) rather than needing a hand-tuned
threshold per material. Worth reusing this approach directly if a
future cutout mixes very pale and very saturated/dark colors in the
same image against one saturated backdrop -- the button and star
cutouts never hit this because their colors were all in a narrower,
more uniform saturation range.

One more round on this same asset: the creator flagged a small pink
mark specifically on the leftmost flower in all three cutouts. Turned
out not to be a cutout defect at all -- a good amount of time went into
treating it like the alpha-estimation bug above (checking core
coverage and edge thickness right at that flower) before the creator
caught their own mistake and clarified it was a mark on their source
images themselves. Re-cut all three variants once the creator sent a
corrected render for each in turn (day, then golden hour, then night)
-- all clean now. Worth remembering: a localized, oddly-shaped defect
isolated to one small feature is at least as likely to be bad source
content as a pipeline bug, especially once the same pipeline has
already proven clean everywhere else in the same image.

Second filler variant is a palm tree ("palmier"), cut from the same
magenta/purple chroma-key family as the frangipanier and now with a
complete day/golden/night set of its own too. Held up fine against the
fern-like fronds' many thin, narrow leaflets -- each notch between
leaflets could in principle starve the nearest-core-projection method
of any real core pixels the way the plumeria's one small bud did, but
here the fronds are wide enough relative to the transition band that
didn't happen. One thing that looked like a defect on first pass,
right at those same notches, was a dark maroon tint along several
leaflet edges -- traced back to the original source (not the cutout)
and it's really there, a rim-shadow between overlapping leaflets baked
into the render, so it was left alone rather than "fixed" into
something the creator never drew.

The creator's next reaction, though, was a fair "fait a l'arrache" ("a
bit rushed") pointed specifically at the palmier's outline -- and
looking closer, the silhouette really was jaggier/more staircase-y than
the frangipanier's. Root cause: this file's alpha is derived from the
source's own transition width, and the palmier's transition turned out
to be extremely narrow -- one profile measured a jump from alpha 197
to 7 across a single pixel. The smoothstep curve applied on top
sharpens a transition rather than softening one, so a 1px-wide edge
stayed a 1px-wide edge -- fine on the frangipanier's large, rounded,
softly-lit petals where a hard pixel step is easy to miss, glaring on
the palmier's long thin diagonal frond edges where it reads as a
staircase. Fixed with a small Gaussian blur (sigma ~0.9px) on top of
the existing alpha -- done as a premultiplied-alpha blur (blur
color*alpha and alpha together, then divide back out) rather than
blurring alpha alone, so a softened edge pixel inherits real nearby
color instead of an undefined one from deep in the background. Applied
to all three palmier periods; the frangipanier and the other earlier
cutouts have the same narrow-transition trait underneath but read fine
without it, so they were left as they are rather than reprocessed on
spec.

That still wasn't the whole story: the creator zoomed into the pushed
result and pointed at real leftover magenta/pink specks, still visible
scattered through the fronds. This was a second, different bug from
the jagged edges -- some of the tiny (10-30px) genuine gaps between
overlapping leaflets were getting swept up by this file's usual
size-gated hole-fill (meant to patch single-pixel JPEG noise, not real
gaps) and baked in as solid, wrong-colored patches once erosion
happened to leave part of a filled gap untouched deep inside a wide
part of a frond. Tightening the fill-size cutoff alone wasn't reliable
either -- the real gaps here range continuously from a few px up to
~30px with no clean size gap from true noise to separate them by
threshold. Fixed properly with a ground-truth check instead of a size
guess: a pixel is only ever allowed full ("core") opacity if its own
raw color actually differs from the background past the same distance
threshold (40) that defined the silhouette in the first place, no
matter how deep inside the hole-filled shape erosion placed it, and
the same pixels get their non-core alpha capped low too rather than
picking up a partial tint from a nearby filled micro-hole's edge. Cut
the visible speck count by roughly 8-10x on the two magenta-background
periods (day, golden); night, on a different purple background, had
none to begin with. What's left is a handful of single-pixel specks
invisible at anything but 5x zoom -- reasonable to leave rather than
chase further.

Every node and decor piece also casts a contact shadow now -- the
creator asked directly how the scroll would actually read as "resting
on a curved surface" rather than flat stickers pasted over it.
`_contactShadow` in `progression_map_screen.dart` draws a soft ellipse
at each item's foot using the *same* projected `point` (scale +
opacity) the item itself was drawn with, so the shadow shrinks and
fades in lockstep as the item rolls away over the drum instead of
sitting at a fixed size underneath it. It's a flat radial gradient, not
an actual blurred one -- close enough visually at this size, and
avoids stacking an `ImageFiltered` blur on top of a dozen-plus items
that can be on screen at once. Each shadow shares its owner's
depth-sort scale (nudged a hair lower so it's guaranteed to land
immediately behind, since `List.sort` isn't stable on ties) rather than
getting sorted independently, so it can't end up drawn in front of a
nearer item or behind a farther one it has nothing to do with.

Also worth knowing: per-level star history (1-3 stars per completed
level) isn't tracked server-side yet -- `ProgressDTO` only carries a
single `unlockedLevel` -- so every validated level currently shows a
placeholder full 3 stars. And the level buttons' tap gesture and the
screen's own drag-to-scroll gesture are both plain `GestureDetector`s
layered on top of each other; Flutter's gesture arena usually resolves a
quick tap vs. a real drag correctly by default, but this hasn't been
exercised on a real device either -- worth a specific check once it can
be run.

`08-page-accueil.md`'s "PLAY" now pushes straight into this screen
(after a best-effort `authenticateWithDevice()` so progress can load;
falls back to "nothing validated" if offline or the backend isn't
reachable). Tapping a level, or any of the three HUD buttons without a
screen yet (rewards, shop, and the heart/coin counters themselves), lands
on the same `ComingSoonScreen` stub used elsewhere (now shared, pulled out
of `home_screen.dart` into `lib/widgets/coming_soon_screen.dart`).

## Mission sheet (`10-fiche-mission-niveau.md`)

Tapping a level node on the progression map now opens the mission sheet
(`lib/screens/level_mission_screen.dart`) instead of going straight to
the old stub. Per the spec ("apparaît en superposition devant la carte,
carte visible en arrière-plan") this is an overlay, not a screen that
replaces the map: `_openLevel` in `progression_map_screen.dart` pushes
it via a `PageRouteBuilder` with `opaque: false` rather than the usual
`MaterialPageRoute`, so the map screen stays mounted underneath instead
of being torn down. The overlay itself draws a `BackdropFilter` blur +
dark scrim across the whole screen (blurring the map behind it) with
the mission card centered on top; tapping outside the card pops the
route back to the map, tapping the card itself doesn't (a second
`GestureDetector` around the card swallows the tap before it reaches
the scrim's dismiss handler).

The card's own "verre dépoli mat façon velours, blanchâtre et
légèrement transparent" look is just a semi-opaque white
(`Colors.white.withOpacity(0.88)`) rounded container with no blur filter
of its own -- it doesn't need one, since it's sitting on top of the
screen-wide blur already; its own translucency is what lets a soft hint
of the blurred map show through. The "Niveau N" title's sticker-style
white outline is 8 offset white copies of the text stacked behind the
brown fill copy (`_OutlinedTitle`) -- simpler and more reliable at this
font size than a stroke-style `Paint`, which doesn't blend cleanly with
a separate fill pass on small text.

Two new models back the variable content:

- `lib/models/level_mission.dart` -- `LevelMission`/`MissionTarget`/
  `MissionType`. Only one mission type exists in the spec so far
  ("Complète la commande" -- collect N of one or two target
  `GameElement`s), modeled as an enum anyway so a second type can be
  added later without reshaping the class. `LevelMissionGenerator.forLevel`
  is deterministic (seeded by level number, not persisted) and reuses the
  spec's own calibrated count -- 15 individual elements per target,
  the exact number the spec gives for level 1 to guarantee "ne doit
  jamais pouvoir être terminée en moins de 2 minutes" -- for every level,
  rather than inventing a difficulty curve with no board-speed data to
  justify one (that's `11-ecran-de-jeu.md` territory). Level 1
  specifically reproduces the spec's own worked example exactly
  (croissant × 15, single target) instead of leaving it to the same
  per-level roll every other level gets. About 30% of levels get a
  second target element, per "peut porter sur plusieurs éléments à la
  fois" -- capped at 2 so the mission row still fits the card's fixed
  width cleanly (the spec's own "chaque mission doit être conçue pour
  bien s'adapter visuellement à la fiche").
- `lib/models/boost_inventory.dart` -- a flat placeholder map, every
  boost at 0. There's no backend inventory (`ProgressDTO` only carries
  lives/coins/xp), no way to earn a boost (`14-boutique.md` isn't built),
  and no way to spend one in a level (`11-ecran-de-jeu.md` isn't built
  either) -- so rather than inventing plausible-looking starting
  quantities, every boost honestly shows 0 and reads as dimmed and
  inert on the sheet until that whole loop exists.

Selecting a boost (per the spec: "en cliquant sur la zone affichant la
quantité possédée d'un bonus, une animation d'enfoncement indique
lequel est sélectionné") is a tap-to-toggle on the count pill
specifically -- not the icon above it, matching the spec's own scoping
of the tappable zone to where the quantity is shown. Toggling reuses
`SpringButton` for the per-tap bounce every button in the game gets,
layered under an `AnimatedContainer` that eases the pill itself into a
flatter, lighter "pushed in" look while selected (no native inset
shadow in Flutter, so a lighter fill + a dropped shadow read as
"pressed" here) -- the transient spring bounce alone wouldn't carry a
*persistent* selected state on its own. Selection is capped at
`maxEquippedBoosts` (already defined in `boost_power.dart`, unused
until now) and a boost at 0 owned can't be selected at all -- currently
true for all five, so the whole row is inert until real inventory
exists, which is the honest state of things right now. "JOUER" leads to
the same `ComingSoonScreen` stub ("Le niveau N arrive avec
11-ecran-de-jeu.md") the level button itself used to go straight to.

Like every other screen in this app so far, this hasn't been run on an
actual device or simulator from this environment -- the layering
(`BackdropFilter` + two nested `GestureDetector`s for
dismiss-vs-swallow), the outlined-title stacking trick, and the
pressed-pill look are reasoned through, not visually confirmed.

## Game screen (`11-ecran-de-jeu.md`) — core engine in, the rest deferred

"JOUER" on the mission sheet now leads into a real match-3 board
instead of the old stub. This is the biggest single feature built in
this project so far by a wide margin, so it got the same treatment the
progression map did: build the core engine for real, defer everything
around it with an honest stand-in rather than half-building the whole
spec across the board.

**What's built:**

- `lib/models/game_board.dart` (`GameBoard`) -- pure Dart, no Flutter
  dependency, so it's the one piece of this file worth unit-testing
  directly if tests get added later. Generates a 7x7 grid (see below)
  guaranteed to open with no pre-existing match and at least one legal
  move; validates a swap by actually trying it and checking for a match
  rather than special-casing adjacency math, reverting if none; resolves
  a full cascade (clear → collapse each column (with new pieces falling
  from the top, not conjured mid-column) → re-check → repeat) in one
  call, returning per-element counts for the mission tracker and a total
  for star-dust; and reshuffles the *existing* pieces (not fresh random
  ones) into a new match-free, at-least-one-legal-move arrangement for
  "plateau bloqué." `hasAnyValidMove` is the brute-force "try every
  adjacent pair, check, revert" approach -- perfectly fine at these
  board sizes, would need a smarter approach at 10x50 (see below).
- `lib/screens/game_screen.dart` (`GameScreen`) -- the board rendered on
  a translucent glass panel (the same visual language as the mission
  sheet's card, without its own blur since there's no previous screen to
  blur through here), both input methods from the spec (tap a cell then
  an adjacent one, or drag), the top HUD (moves / star bar + mission
  icon+counter / lives) and bottom HUD (selected boosts row) from the
  spec's own layout, real-time mission progress (updates the moment a
  cascade resolves, just without the "element flies to the counter"
  animation), the star-dust bar, shuffle-when-blocked, and win/lose
  detection.

**Reasoned-not-measured numbers**, since the spec gives exactly one
calibrated example and nothing else: 7x7 board and 25 starting moves
both come straight from the spec's own "les chiffres visibles sur cet
exemple sont les valeurs réelles d'un niveau facile" -- reused for
every level since there's no board-size or move-budget curve to scale
them by. Star-dust is 1 point per cleared piece plus a flat
`3 × mouvements restants` bonus at victory (standing in for the
"étoile filante par mouvement restant" mechanic's score contribution,
without its animation), against thresholds anchored to the mission's
own total target count (`missionTotal`, `×1.5`, `×2` for 1/2/3
stars) -- there's no real balancing data behind any of this, and it's
written to be trivially retunable once there is.

**Deliberately deferred** (same "cœur d'abord, reste en suivi" scoping
the creator set for `09-carte-progression.md`):

- **Special pieces** (tourbillon, bombe aux éclats, rayée --
  `special_piece.dart`, from `05-mecaniques-de-jeu.md`). A 4/5-in-a-row
  or T/L match just clears normally right now; detecting the pattern and
  spawning/triggering the piece is real work layered on top of the
  match-finder that exists, not started.
- **Obstacles and delivery objectives** (`obstacle.dart`,
  `delivery_objective.dart`). Every board cell is a plain `GameElement`
  -- no vitrine/caramel/cookie/macaron blocking a cell, no chantilly/sac
  de café traveling down the board by gravity.
- **Boost activation.** The bottom HUD displays the loadout chosen on
  the mission sheet but tapping one does nothing -- the 5 different
  targeting UIs from `06-pouvoirs-des-bonus.md` (`BoostTargeting`: tap a
  column, tap an element, tap to pick a type, no target, source-then-
  off-board-destination) don't exist yet. Moot right now anyway since
  every boost quantity is still 0 (`10-fiche-mission-niveau.md`'s
  `BoostInventory` placeholder).
- **The 10-second hint glow** ("aide au joueur"). Not implemented --
  the board never highlights a possible match on its own.
- **The shuffle's own animation.** `shuffleUntilPlayable()` runs
  instantly and silently; the spec's "tous les éléments se mélangent
  puis se replacent" implies a visible shuffle animation that doesn't
  exist yet.
- **Loading/opening animation.** Explicitly "prévue mais pas encore
  réalisée" in the spec itself -- the board is simply already in place
  when the screen opens, matching that.
- **Win/lose popups themselves were built next** -- see the
  `12-popups-fin-de-niveau.md` section below. `GameScreen._finishLevel`
  now pushes the real `LevelWonPopup`/`LevelLostPopup` instead of a
  placeholder dialog.
- **Board-size/move-budget progression, biome/mission-type alternation**
  (`03-assets-de-jeu.md`'s own deferred note: "board size/shape
  progression from 7x7 up to 10x50 around level 1000, mandatory shape
  variety and mission-type alternation between consecutive levels").
  Still no data to build this from.
- **Whether starting a level spends a life.** `ApiClient.consumeLife()`
  exists but is still never called anywhere -- no spec file has said
  when it should fire.

**Implementation notes worth flagging:**

- The board is a hand-rolled `Column` of `Row`s, not a `GridView` --
  `GridView`'s `Scrollable` still participates in the gesture arena even
  with `NeverScrollableScrollPhysics` (that disables scrolling, not
  arena participation), which would have fought each cell's own drag
  detector, especially for vertical swipes. Nothing here needs scrolling
  or lazy building anyway at a fixed 7x7 size.
- The "effet de rebond" on an invalid swap is a squash/spring *scale*
  punch on the two involved cells (one shared `AnimationController` for
  the whole board, since only one bounce plays at a time), not the two
  cells actually sliding toward each other and back -- simpler to get
  right, and still a clear "no" as feedback. Likewise, a cascade's
  clears/refills currently just pop into their new state; pieces don't
  visually fall tile-by-tile. Both are candidates for a later animation
  pass, not correctness gaps.
- No dedicated "table de jeu" background art exists -- the screen reuses
  the real home-screen background (day/golden/night aware, same as
  everywhere else) rather than inventing a new photo.
- Not run on a device or simulator from this environment, same caveat as
  every other screen in this app -- the gesture-arena reasoning above
  and the animation timings are worked through on paper, not watched.

## End-of-level popups (`12-popups-fin-de-niveau.md`)

`GameScreen._finishLevel` now pushes one of two real popups
(`lib/screens/level_end_popups.dart`) instead of the placeholder
`AlertDialog` from the `11-ecran-de-jeu.md` pass -- both on the same
"verre dépoli mat façon velours" frosted card the mission sheet uses,
via the same blur-scrim-over-whatever's-behind overlay pattern. The
sticker-style outlined title ("Niveau N" on the mission sheet, "PERDU"/
"GAGNÉ" here) got pulled out into a shared `StickerText` widget
(`lib/widgets/sticker_text.dart`) rather than staying duplicated once a
second screen needed it.

**`LevelLostPopup`**: lives remaining, "C'est pas fini !", and two
buttons plus a corner "X". "+5 mouvements gratuit !" is spec'd to need
a 30-second-minimum video ad -- no ad SDK exists anywhere in this
project (nothing in `pubspec.yaml`), so this is an honest stub
(`ComingSoonScreen`) rather than a fake ad flow. "Rejouer" relaunches
the level (fresh `GameScreen`, same mission and boost loadout, since
the mission is deterministic per level number anyway) if lives remain,
or redirects to the not-yet-built shop otherwise, per the spec's own
branching rule. The "X" badge overlaps the card's bottom-left corner,
per the reference mockup -- it has to be part of the card widget itself
(`_withCloseButton`), not positioned by the outer scaffold: a
`Positioned` there would anchor to the full-screen backdrop that
actually sizes that outer `Stack`, not to the card floating centered
inside it.

**`LevelWonPopup`**: score, 1-3 stars, "Continuer", with fireworks
behind the card. The score counts up via an `IntTween` under an
`easeOutCubic` curve, paired with an `elasticOut` scale-in -- reading
the spec's "incrémente par palier de 1 point" as *how* the animation
moves (through whole integers, not a smoothly-interpolated fraction)
rather than literally one point at a time, which would take minutes
for the reference mockup's own "1,250,000". No real firework art
exists (and photographic firework content isn't something to
fabricate), so the fireworks are a small procedural `CustomPainter`
effect instead -- a handful of staggered radiating-line bursts, same
spirit as the progression map's twinkling night-sky stars or its
contact shadows: a generated effect, not standing in for a missing
photo.

Every button here that leaves the popup (`X`, `Rejouer`, `Continuer`)
goes through `LoadingTransitionOverlay`
(`lib/widgets/loading_transition_overlay.dart`) via
`Navigator.pushAndRemoveUntil`, discarding the whole mission-sheet/
game-screen/popup stack in favor of a fresh destination screen (the
map, or a new `GameScreen` for a replay) wrapped in that transition --
matching the spec's own "animation de chargement" language for each of
these. This is that widget's first real use anywhere in the app: it
existed since `07-regles-globales-ui.md`, fully built, explicitly
"pas encore wired into any navigation flow" until this pass gave it
one, with 8 background variants to cycle through and a 2-second display
cap already handled internally.

Whether starting or losing a level spends a life is still undefined by
any spec file reached so far -- `ApiClient.consumeLife()` still isn't
called anywhere, same as noted in the `11-ecran-de-jeu.md` section.
Lives shown here are just whatever was passed down from the map's last
fetched `ProgressDTO`, unchanged for the whole session. Not run on a
device or simulator from this environment, same caveat as everything
else.

## Rewards screen (`13-ecran-recompenses.md`)

Reached from the map's bottom HUD "café" icon (`onRewards`, previously
a stub), `RewardsScreen` (`lib/screens/rewards_screen.dart`) is a
battle-pass-style vertical list of tiers, one every `xpPerRewardTier`
(30 000) XP, each granting the same fixed bundle (`rewardTierBundle` in
`lib/models/reward_tier.dart`) on a free (left) and premium/subscriber
(right) side. No back button anywhere -- the spec's "uniquement swipe
gauche/droite pour quitter" is enforced for real: `PopScope(canPop:
false)` blocks the system back button/gesture, and only this screen's
own `onHorizontalDragEnd` (velocity threshold) can leave it.

**Reading the two mockups against the prose**: both the "état initial"
and "palier atteint" reference screenshots show the same pill shape at
the same spot on each tier's bar, while the prose separately describes
a "la barre réapparaît où le joueur l'avait laissée, avance rapidement
jusqu'à sa position actuelle en ralentissant à l'arrivée" catch-up
animation. Taken together, that reads as: the pill is a **static cap
marker** per tier (just glowing once that tier is unlocked), and the
actual animated "fill" is the **scroll position** advancing up a long
vertical list of tiers as XP grows, not an in-tier fill gauge. That's a
reasoned interpretation, not something confirmed by the creator --
flagging it here in case the real intent was a continuous gauge inside
each pill.

**Catch-up animation**: the last XP value the player saw this screen at
is stored locally (`SharedPreferences`, `coffeebreak.rewardsLastSeenXp`
-- same lightweight local-persistence pattern as the session token in
`ApiClient`). On open, if XP grew since last visit, the list jumps
straight to the old scroll position (no animation, since nothing should
visibly move yet) and then eases to the new one over 900ms. First-ever
visit stores the current XP without animating from zero, since that
would fabricate a "gap" that was never real.

**Claiming a reward**: tapping an unlocked, unclaimed icon plays a
2-second scale-and-glow-then-slide-off-screen animation
(`_ClaimAnimationOverlay`), matching the spec's "s'affiche en plein
milieu de l'écran en brillant, puis disparaît rapidement vers la
droite." Claimed state is session-only (a `Set<String>` of tier/item/
column ids) -- there's no backend endpoint to persist a claim yet, same
honest-placeholder pattern as `BoostInventory`. Tapping a premium-column
reward while `_hasActiveSubscription` is false (always, right now --
no subscription state exists anywhere in this app until
`14-boutique.md`) redirects to `ComingSoonScreen` instead of granting
anything.

No "money bag" asset exists for the mockup's larger x750 coin rewards,
so every coin line item reuses the one real `Currency.coinCafe` sprite,
differentiated only by the printed quantity -- same reasoning as the
small/large coin reuse on the mission sheet's boost-cost mockups back
in `10-fiche-mission-niveau.md`.

Deliberately deferred: only the first 20 tiers are preloaded (no
infinite/lazy generation past that, matching the "cœur d'abord" scoping
used for `09`'s levels and `11`'s board); actual subscription purchase
flow (`14-boutique.md`); persisting a claim server-side. Not run on a
device or simulator from this environment, same caveat as everything
else -- in particular, a subtle Flutter layout rule this file tripped
during self-review is worth a callout for future files: a `Positioned`
widget must sit directly under a `Stack` with nothing but Stateless/
StatefulWidgets in between it and that `Stack`; `IgnorePointer` (used to
make the claim overlay click-through) is itself a RenderObjectWidget,
so it has to wrap the `Positioned`'s *child*, not the other way around.

## Shop (`14-boutique.md`)

`ShopScreen` (`lib/screens/shop_screen.dart`) is now the real destination
for the map's shop HUD icon (`onShop`, previously a stub) and for the
lost popup's "Rejouer" when out of lives (`level_end_popups.dart`'s
`_replay`, same swap). Same no-back-button rule as the rewards screen:
`PopScope(canPop: false)` plus a horizontal swipe to leave
(`lib/models/shop_catalog.dart` holds all the static offer data).

**14.1 — 3 starter packs**: each row's icons follow the reference
mockup's own art rather than the spec text (which calls both pack 1's
and pack 2's coffee item just "café") — pack 1 draws the to-go cup
(`Boost.cafeAEmporter`), pack 2 draws the mug with heart latte art
(`Boost.cafeLatte`). No "money bag" or "treasure chest" asset exists for
the bigger coin rewards on packs 2 and 3's right side, so both reuse the
one real coin sprite (`Currency.coinCafe`) at the same size, differing
only by the printed number — same reasoning as `reward_tier.dart`'s
identical choice. Pack 3's left side is a cluster of 6 small grants
instead of one icon: 3 already-real boost/HUD assets (`cafeAEmporter`,
`jusOrange`, `cafeLatte`, and `hud_heart.png` for "1 vie"), plus two
("boost chrono", "boost infini") that have no dedicated art and no
gameplay definition in any spec file reached so far — the mockup itself
renders those two as plain stopwatch/infinity glyphs rather than
commissioned art, so this reuses that same plain-glyph treatment
(⏱️/♾️ text) instead of inventing new art or a new mechanic.

**"VOIR PLUS"**: hides itself and reveals 14.2's 4 rows below on tap,
per the spec's "disparaît au clic et révèle la suite de la page vers le
bas." All 4 temporary boosts (`tempBoostOffers`) cost 2000 coins for 1h,
distinguished visually with a green price pill instead of 14.1's pink,
matching the mockup's own color split between "real money" and "in-game
coins" purchases. "Outis surprise" is reproduced verbatim, matching a
typo present in both the spec text and the mockup image — almost
certainly meant to be "Outils", flagged here rather than silently
corrected.

**The 20 000 chest row**: the bottom of 14.2's mockup shows a
treasure-chest icon and "20 000" with no price and no label, and isn't
one of the 4 offers the spec text actually lists. Read here as a banner
into 14.3 (tapping it pushes the coin-packs screen) rather than a 5th
temporary boost, since it visually matches 14.3's own biggest tier —
**not confirmed with the creator**, flagging in case the real intent was
something else (a coin-balance display, for instance).

**14.3 — coin-only packs**: its own screen (`_CoinPacksScreen`, private
to `shop_screen.dart`) rather than more of the same scroll, per the
spec's own "Bouton Retour : revient à la boutique principale" implying
a separate place to return *from*. Cyan-bordered price pills, matching
the mockup's third distinct color. Same single-coin-sprite reuse as
14.1 for every row.

**Every priced button — all three sections — is an honest
`ComingSoonScreen` stub**, not a payment flow that can't actually
complete: no IAP plugin exists anywhere in `pubspec.yaml`
(`in_app_purchase` or otherwise), and the backend's
`POST /iap/validate-receipt` (`backend/src/routes/iap.ts`) still can't
verify a real Apple/Google receipt or credit a product — it's already
flagged there with a `TODO` for exactly this catalog. The Apple/Google
loot-box probability-disclosure requirement for "Bonus surprise"/"Outils
surprise" (`docs/SETUP.md` step 5) is a **store-listing** obligation,
not something this screen can satisfy in-app — nothing here fabricates
percentages for content that doesn't have a defined reward pool yet.

Deliberately deferred: actually spending coins or crediting a purchase
(no backend product catalog yet); the temporary boosts' real gameplay
effects; real payment of any kind. Not run on a device or simulator
from this environment, same caveat as everything else.
