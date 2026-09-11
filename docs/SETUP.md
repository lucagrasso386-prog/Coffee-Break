# Manual setup steps

These are steps that need a human with the right accounts/credentials —
nothing here can be done from the coding session. Checklist, roughly in the
order you'll hit them. iOS and Android are covered in parallel since both
ship at launch (see the root `README.md` architecture note).

## 1. Apple Developer

- [x] Registered the **Bundle ID** `com.lucagiraud.coffeebreak` in Apple
      Developer (uniformized with the creator's other apps; replaces the
      earlier `lux.coffeebreak`), with **Sign In with Apple** and
      **In-App Purchase** capabilities enabled. Already wired into the
      repo: `--org com.lucagiraud` in both iOS GitHub workflows
      (`ios-testflight.yml` also force-sets the exact bundle identifier
      after `flutter create`, rather than relying on Flutter's
      org+project-name conversion to land on this exact string), and
      `backend/.env.example` → `APPLE_BUNDLE_ID`.
- [ ] Create a new **App Store Connect** app record using that Bundle ID.
      (App name comes from `02-identite-visuelle.md`.) The earlier record
      created under `lux.coffeebreak` can't be reused for the new Bundle
      ID.
- [x] **Team ID**: `9Q64FWDPM5` — already filled into
      `mobile/ExportOptions.plist`.

## 2. Google Play Console

- [ ] Create (or use the existing) **Google Play Console** developer
      account, and register a new app listing for Coffee Break.
- [ ] Pick the **Application ID** (Android's equivalent of a Bundle ID) —
      `com.lucagiraud.coffeebreak`, matching the iOS Bundle ID, is the
      natural default unless there's a reason to diverge (they're
      independent namespaces).
- [ ] In [Google Cloud Console](https://console.cloud.google.com/) (same
      Google account/org as Play Console), create an **OAuth 2.0 Client ID**
      for Sign in with Google:
  - An **Android** client ID, registered with the Application ID and the
    release keystore's SHA-1 fingerprint (Play App Signing provides this
    once the app is uploaded once).
  - A **Web** client ID — this is the one the backend actually verifies
    tokens against. Put it in `backend/.env` as `GOOGLE_CLIENT_ID`.
- [ ] Enable **Play App Signing** when first uploading a build — Google
      manages the release signing key from then on.

## 3. GitHub Actions (build the iOS app on a Mac you don't own)

No Mac is available anywhere in this project's toolchain (not this coding
session, and per your setup, not you either) — but building an iOS `.ipa`
and signing it for TestFlight is an Apple requirement that always needs a
real Mac somewhere. GitHub Actions can run jobs on Apple's own `macos`
runners, for free within GitHub's monthly minutes — no third-party account
needed, since it's a setting on this repo you already own. Two workflows
are already in the repo:

- `.github/workflows/ios-build-check.yml` — compiles unsigned on every push
  that touches `mobile/`, no secrets needed, just to catch build breaks early.
- `.github/workflows/ios-testflight.yml` — signs a real build and uploads it
  to TestFlight. Manually triggered (from GitHub's Actions tab, or by asking
  the assistant to trigger it via the GitHub API — no need to open GitHub
  yourself either way).

The signing step needs five secrets, added once in **this repo's** Settings
→ Secrets and variables → Actions → New repository secret (this is a GitHub
setting under your existing account, not a new external service):

- [ ] **App Store Connect API key** (App Store Connect → Users and Access →
      Integrations → App Store Connect API → generate a key with **App
      Manager** access): gives you an Issuer ID, a Key ID, and a `.p8` file
      to download once (Apple only lets you download it once — save it).
      Store as:
  - `ASC_ISSUER_ID`
  - `ASC_KEY_ID`
  - `ASC_KEY_P8` — the full contents of the downloaded `.p8` file
- [ ] **Distribution certificate**: in Apple Developer → Certificates,
      create (or reuse) an **Apple Distribution** certificate, export it
      from Keychain Access as a `.p12` file with a password you choose.
      Store as:
  - `IOS_DIST_CERT_P12` — the `.p12` file, base64-encoded
    (`base64 -i cert.p12 | pbcopy` on a Mac, or any base64 tool)
  - `IOS_DIST_CERT_PASSWORD` — the password you set when exporting
- [ ] **Keychain password**: any random string you make up, used only to
      protect the temporary keychain the workflow creates and deletes on
      each run. Store as `IOS_CI_KEYCHAIN_PASSWORD`.
- [x] Team ID filled into `mobile/ExportOptions.plist` (see step 1).
- [ ] In App Store Connect, add yourself as a tester (your Apple ID, the one
      your iPhone is signed into) to an **Internal Testing** group — no
      review needed for internal testers.
- [ ] Trigger the `ios-testflight` workflow once everything above is in
      place. Once it succeeds, the build shows up in the **TestFlight** app
      on your iPhone within a few minutes.
- [ ] These two workflow files were written without being able to run them
      here (no macOS runner access from the coding session either) — if the
      first run fails on a config error rather than a code error, paste the
      error back and it'll get fixed.

Android has no such gap: `flutter run` straight from a laptop onto a phone
over USB works without any of this, since Google doesn't require a
proprietary OS to build for its own platform.

## 4. Firebase (push notifications)

`07-regles-globales-ui.md` requires prompting the player to allow push
notifications. The client side (`mobile/lib/services/notification_service.dart`)
is already written against `firebase_messaging`, which needs a real Firebase
project:

- [ ] Create a Firebase project (or reuse an existing one) at
      [console.firebase.google.com](https://console.firebase.google.com/).
- [ ] Add an iOS app to it using the Bundle ID from step 1, download the
      generated `GoogleService-Info.plist`, and add it to
      `mobile/ios/Runner` once that folder exists (after `flutter create .`,
      see `mobile/README.md`).
- [ ] Add an Android app to it using the Application ID from step 2,
      download `google-services.json`, and add it to `mobile/android/app`
      once that folder exists.
- [ ] Upload your Apple Push Notification key (Apple Developer → Keys →
      create one with the **Apple Push Notifications service** capability)
      to Firebase project settings → Cloud Messaging → APNs Authentication
      Key, so Firebase can actually deliver to iOS devices.
- [ ] Call `Firebase.initializeApp()` at the top of `main()` once both
      config files above are in place — deliberately not wired up yet
      (see the doc comment on `notification_service.dart`), since doing so
      without them would crash the app on startup instead of just no-op-ing.
- [ ] Still open, not part of this step: server-side sending (Firebase
      Admin SDK in the backend, storing each user's push token, and
      something that actually decides when to send — e.g. on the lives-refill
      timer in `backend/src/lib/lives.ts`). Flagged as deferred work, not
      started.

## 5. In-App Purchase products

- [ ] In App Store Connect **and** Google Play Console, create the IAP
      products once `14-boutique.md` defines the catalog: consumable coin
      packs + the premium subscription. The two stores have separate
      product catalogs even for the same product.
- [ ] **Loot box disclosure**: "Bonus surprise" / "Outils surprise" are
      randomized-content purchases. Apple has an explicit loot box rule
      (App Store listing must publicly show the probability of obtaining
      each possible reward *before* purchase); Google Play has an
      equivalent Loot Box policy requiring the same disclosure. Flag this
      when building the shop screen (`14-boutique.md`) and the
      corresponding product page copy on both stores.
- [ ] Generate an **In-App Purchase** App Store Connect API key (Users and
      Access → Integrations → In-App Purchase) for server-side receipt
      validation. You'll get an Issuer ID, Key ID, and a `.p8` private key —
      put them in `backend/.env` as `APPLE_ISSUER_ID`, `APPLE_KEY_ID`,
      `APPLE_IAP_PRIVATE_KEY`. (Separate key from the App Store Connect API
      key used for signing in step 3 — different access scope.)
- [ ] Generate a **Google Play Developer API** service account (Play
      Console → Users and permissions → API access) for server-side receipt
      validation on Android. The backend doesn't verify Google Play receipts
      yet — flagged as open work in `backend/README.md`.

## 6. Beta testing

- [ ] **TestFlight** (iOS): covered by step 3 for internal testing; external
      testing invites up to 10,000 testers via email or a public link once
      you're ready for broader feedback.
- [ ] **Play Console testing tracks** (Android): internal testing available
      immediately; closed/open testing tracks for broader feedback, each
      requiring a short review the first time.

## 7. Railway (backend)

- [ ] Create a Railway project.
- [ ] Add a **Postgres** plugin to it.
- [ ] Add a service for this repo with **root directory** set to `backend/`.
- [ ] Set environment variables from `backend/.env.example`
      (`DATABASE_URL` is injected automatically by the Postgres plugin).
- [ ] Deploy — Railway picks up `backend/railway.json` (Nixpacks build,
      runs Prisma migrations then starts the server).
- [ ] Once you have the live URL, update
      `mobile/lib/models/app_config.dart` → `apiBaseUrl`.

## 8. Privacy policy

- [ ] Publish `docs/PRIVACY_POLICY.md` (fill in the placeholders first)
      somewhere public — either:
  - GitHub Pages: enable Pages on this repo for the `docs/` folder, or
  - a static route served by the Railway backend.
- [ ] Required in both App Store Connect and Google Play Console because the
      app has both IAP and user accounts (Play Console: Data safety section
      also needs filling in from the same policy).

## 9. Store submission (once the app is ready)

- [ ] **App Store Connect**: product page (screenshots, description, age
      rating, Privacy Nutrition Label), link the privacy policy URL from
      step 8.
- [ ] **Google Play Console**: store listing (screenshots, description,
      content rating questionnaire, Data safety form), link the privacy
      policy URL from step 8.
