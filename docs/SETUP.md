# Manual setup steps

These are steps that need a human with the right accounts/credentials —
nothing here can be done from the coding session. Checklist, roughly in the
order you'll hit them. iOS and Android are covered in parallel since both
ship at launch (see the root `README.md` architecture note).

## 1. Apple Developer

- [ ] In the existing Apple Developer account, register a **new Bundle ID**
      for Coffee Break, distinct from the other app (e.g.
      `com.yourcompany.coffeebreak` — replace `yourcompany` with your real
      reverse-DNS prefix).
  - Enable capabilities: **Sign In with Apple**, **In-App Purchase**.
- [ ] Create a new **App Store Connect** app record using that Bundle ID.
      (App name comes from `02-identite-visuelle.md`.)
- [ ] Update the Bundle ID in three places once created:
  - `codemagic.yaml` → `bundle_identifier` (and `APP_STORE_APPLE_ID`, the
    numeric Apple ID shown in App Store Connect → App Information)
  - the generated `mobile/ios/Runner.xcodeproj` (via Xcode's Signing &
    Capabilities tab, after running `flutter create .` — see
    `mobile/README.md`) — only needed if you also build locally on a Mac
  - `backend/.env` → `APPLE_BUNDLE_ID`

## 2. Google Play Console

- [ ] Create (or use the existing) **Google Play Console** developer
      account, and register a new app listing for Coffee Break.
- [ ] Pick the **Application ID** (Android's equivalent of a Bundle ID, e.g.
      `com.yourcompany.coffeebreak` — keep it matching the iOS Bundle ID for
      consistency, though they're independent namespaces).
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

## 3. Codemagic (build the iOS app on a Mac you don't own)

No Mac is available anywhere in this project's toolchain (not this coding
session, and per your setup, not you either) — but building an iOS `.ipa`
and signing it for TestFlight is an Apple requirement that always needs a
real Mac somewhere. [Codemagic](https://codemagic.io) rents that Mac by the
build-minute and can push straight to TestFlight when it's done, so this is
how you test on your iPhone without buying one. `codemagic.yaml` at the repo
root is already configured for this — it just needs your credentials, which
only you can provide:

- [ ] Create a Codemagic account and connect it to this GitHub repo.
- [ ] In Codemagic → your team → **Integrations** → **App Store Connect**,
      add an API key:
  - In App Store Connect → Users and Access → Integrations → App Store
    Connect API, generate a key with **App Manager** access.
  - Give the Codemagic integration the exact name `coffee_break_asc_api_key`
    (or update that name in `codemagic.yaml` to match whatever you chose).
- [ ] Fill in the two placeholders in `codemagic.yaml`:
  `bundle_identifier` and `APP_STORE_APPLE_ID` (see step 1 above).
- [ ] In App Store Connect, create an **Internal Testers** TestFlight group
      (or rename the `beta_groups` entry in `codemagic.yaml` to match a
      group you already have) and add yourself to it with the Apple ID your
      iPhone is signed into.
- [ ] Start the `ios-testflight` workflow manually from the Codemagic
      dashboard. Once it succeeds, the build shows up in the **TestFlight**
      app on your iPhone within a few minutes (first build on a fresh Apple
      ID/device sometimes needs the TestFlight invite email accepted first).
- [ ] `codemagic.yaml` was written without being run against Codemagic's own
      validator (no access to Codemagic from the coding session either) — if
      the first build fails on a config error rather than a code error,
      paste the error back and it'll get fixed.

Android has no such gap: `flutter run` straight from a laptop onto a phone
over USB works without any of this, since Google doesn't require a
proprietary OS to build for its own platform.

## 4. In-App Purchase products

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
      key used for Codemagic in step 3 — different access scope.)
- [ ] Generate a **Google Play Developer API** service account (Play
      Console → Users and permissions → API access) for server-side receipt
      validation on Android. The backend doesn't verify Google Play receipts
      yet — flagged as open work in `backend/README.md`.

## 5. Beta testing

- [ ] **TestFlight** (iOS): covered by step 3 for internal testing; external
      testing invites up to 10,000 testers via email or a public link once
      you're ready for broader feedback.
- [ ] **Play Console testing tracks** (Android): internal testing available
      immediately; closed/open testing tracks for broader feedback, each
      requiring a short review the first time.

## 6. Railway (backend)

- [ ] Create a Railway project.
- [ ] Add a **Postgres** plugin to it.
- [ ] Add a service for this repo with **root directory** set to `backend/`.
- [ ] Set environment variables from `backend/.env.example`
      (`DATABASE_URL` is injected automatically by the Postgres plugin).
- [ ] Deploy — Railway picks up `backend/railway.json` (Nixpacks build,
      runs Prisma migrations then starts the server).
- [ ] Once you have the live URL, update
      `mobile/lib/models/app_config.dart` → `apiBaseUrl`.

## 7. Privacy policy

- [ ] Publish `docs/PRIVACY_POLICY.md` (fill in the placeholders first)
      somewhere public — either:
  - GitHub Pages: enable Pages on this repo for the `docs/` folder, or
  - a static route served by the Railway backend.
- [ ] Required in both App Store Connect and Google Play Console because the
      app has both IAP and user accounts (Play Console: Data safety section
      also needs filling in from the same policy).

## 8. Store submission (once the app is ready)

- [ ] **App Store Connect**: product page (screenshots, description, age
      rating, Privacy Nutrition Label), link the privacy policy URL from
      step 7.
- [ ] **Google Play Console**: store listing (screenshots, description,
      content rating questionnaire, Data safety form), link the privacy
      policy URL from step 7.
