# Manual setup steps

These are steps that need a human with the right accounts/credentials —
nothing here can be done from the coding session. Checklist, roughly in the
order you'll hit them.

## 1. Apple Developer

- [ ] In the existing Apple Developer account, register a **new Bundle ID**
      for Coffee Break, distinct from the other app (e.g.
      `com.yourcompany.coffeebreak` — replace `yourcompany` with your real
      reverse-DNS prefix).
  - Enable capabilities: **Sign In with Apple**, **In-App Purchase**.
- [ ] Create a new **App Store Connect** app record using that Bundle ID.
      (App name comes from `02-identite-visuelle.md`.)
- [ ] Update the Bundle ID in two places once created:
  - `ios/project.yml` → `PRODUCT_BUNDLE_IDENTIFIER`
  - `backend/.env` → `APPLE_BUNDLE_ID`

## 2. In-App Purchase products

- [ ] In App Store Connect, create the IAP products once
      `14-boutique.md` defines the catalog: consumable coin packs +
      the premium subscription.
- [ ] **Loot box disclosure**: "Bonus surprise" / "Outils surprise" are
      randomized-content purchases and fall under Apple's loot box rule —
      each product's App Store listing must publicly show the probability
      of obtaining each possible reward *before* purchase. Flag this when
      building the shop screen (`14-boutique.md`) and the corresponding
      product page copy.
- [ ] Generate an **In-App Purchase** App Store Connect API key (Users and
      Access → Integrations → In-App Purchase) for server-side receipt
      validation. You'll get an Issuer ID, Key ID, and a `.p8` private key —
      put them in `backend/.env` as `APPLE_ISSUER_ID`, `APPLE_KEY_ID`,
      `APPLE_IAP_PRIVATE_KEY`.

## 3. TestFlight

- [ ] Internal testing group: available immediately, no Apple review needed.
- [ ] External testing: invite up to 10,000 testers via email or a public
      link once you're ready for broader feedback.

## 4. Railway (backend)

- [ ] Create a Railway project.
- [ ] Add a **Postgres** plugin to it.
- [ ] Add a service for this repo with **root directory** set to `backend/`.
- [ ] Set environment variables from `backend/.env.example`
      (`DATABASE_URL` is injected automatically by the Postgres plugin).
- [ ] Deploy — Railway picks up `backend/railway.json` (Nixpacks build,
      runs Prisma migrations then starts the server).
- [ ] Once you have the live URL, update
      `ios/CoffeeBreak/Models/AppConfig.swift` → `apiBaseURL`.

## 5. Privacy policy

- [ ] Publish `docs/PRIVACY_POLICY.md` (fill in the placeholders first)
      somewhere public — either:
  - GitHub Pages: enable Pages on this repo for the `docs/` folder, or
  - a static route served by the Railway backend.
- [ ] Required in App Store Connect because the app has both IAP and user
      accounts.

## 6. App Store Connect submission (once the app is ready)

- [ ] Product page: screenshots, description, age rating, Privacy Nutrition
      Label.
- [ ] Link the privacy policy URL from step 5.
