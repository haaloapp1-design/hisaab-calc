# Hisab — Google Play listing kit

Everything Play Console asks for to publish Hisab to **closed testing**, in upload order.

| File | What it's for |
|---|---|
| `store-listing.md` | App name, short and full description, category, contact and privacy URL |
| `app-icon-512.png` | Store icon, 512×512 |
| `feature-graphic-1024x500.png` | Banner at the top of the store page |
| `screenshots/01…08-*.png` | Phone screenshots, upload in this order |
| `screenshots/extra/` | Spare screenshots (Convert hub, History) |
| `privacy-policy.md` | Privacy policy; its GitHub URL goes in the listing |
| `app-content-answers.md` | Answers for Data safety, content rating, ads, target audience, etc. |
| `release-notes.md` | "What's new" text for the release |

The app bundle itself is built, not stored here:
`build/app/outputs/bundle/release/app-release.aab` (`flutter build appbundle --release`, signed with the
upload key; see the main `README.md`).

## Before you start (one-time)

- [ ] Replace `[your support email]` in `privacy-policy.md`, then commit and push. The policy URL must load
      in a private browser window.
- [ ] Back up `C:\Users\Ghulam abbas\hisaab-upload-keystore.jks` **and** `android\key.properties` together.
- [ ] **Exchange-rate credit line.** As far as we know, the free open.er-api.com service asks apps to show
      "Rates by Exchange Rate API" with a link to https://www.exchangerate-api.com on the screen that uses
      the rates. Hisab does not show this yet. It's fine for a closed test; add it before going to production.

## Play Console steps

1. **Create app**: name `Hisab – Calculator & Converter`, default language English (United States),
   App, Free. Accept the declarations.
2. **Store listing**: paste the text from `store-listing.md`, then upload the icon, feature graphic and
   screenshots 01–08.
3. **App content**: work through every section using `app-content-answers.md`.
4. **Testing → Closed testing → Create track** (or use the default "Alpha" track):
   - Testers: create an email list and add your testers' Gmail addresses.
   - Countries / regions: choose where testers live (for example Pakistan).
   - **Create new release**: accept **Play App Signing** when asked, upload `app-release.aab`, paste
     `release-notes.md`, then **Review release → Start rollout**.
5. Copy the **opt-in link** from the track's Testers tab and send it to testers. Each tester opens it,
   taps *Become a tester*, then installs Hisab from Play.

## If your developer account is a new personal account

Google requires a closed test with **at least 12 testers opted in for 14 days in a row** before you can
apply for production access. Start the clock as soon as the first review passes, and keep at least 12 testers
opted in for the whole 14 days.

## Updating the test build

1. Raise `version:` in `pubspec.yaml` (`1.0.0+1` → `1.0.1+2`).
2. `flutter build appbundle --release`
3. Closed testing → Create new release → upload → release notes → rollout.

## How the screenshots were made

Taken on 2026-10-29 from the signed release build on an itel NOTE 24 (1080×2460) via `adb exec-out screencap`.
The status bar (top 106 px), 50 px of empty header padding and the gesture bar (bottom 144 px) were cropped
to reach Play's maximum 2:1 aspect ratio (1080×2160). To retake them, open each screen on a phone, capture, and
crop the same rows (156–2316) on a 1080×2460 device.
