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
vice versa. Both pools are still empty (`fillerPool: []`, `landmarkPool: []`
in `_ProgressionMapScreenState`) -- registering a `DecorVariant` per asset
once the creator sends them is the only wiring left; nothing else about
the scatter or the scroll needs to change.

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
