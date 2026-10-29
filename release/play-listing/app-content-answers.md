# App content — answers for Play Console

Play Console → your app → **Policy and programs → App content**. Every section must be completed
before you can send a release for review (closed testing included).

These answers are based on the code as of 2026-10-29: the only network call is the HTTPS
exchange-rate download (`lib/core/currency/currency_repository.dart`); the only permission in the
release manifest is `INTERNET`; there are no ads, analytics, crash reporting, login or in-app purchases.
If you add any of those later, these answers must change.

---

## Privacy policy
URL: `https://github.com/haaloapp1-design/hisaab-calc/blob/master/release/play-listing/privacy-policy.md`
(First replace `[your support email]` in `privacy-policy.md` and push.)

## App access
**All functionality is available without any access restrictions.** (No login.)

## Ads
**No, my app does not contain ads.**

## Content rating (IARC questionnaire)
- Email: your email
- Category: **All other app types** (it is not a game, social, or communication app)
- Answer **No** to every question: violence, sexuality, language, controlled substances, gambling,
  user-generated content / user interaction, sharing location, digital purchases, etc.
- Expected result: **Everyone / PEGI 3 / USK 0** (or the local equivalent).

## Target audience and content
- Target age groups: **18 and over** (you may also tick **13–15** and **16–17**).
- Do **not** tick any group under 13: that puts the app under the Families policy, with extra
  requirements that this app doesn't need.
- "Could your store listing unintentionally appeal to children?" → **No**.

## News app
**No.**

## Data safety
| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | (skipped when "No" above; if asked: **Yes**, HTTPS) |
| Do you provide a way for users to request that their data is deleted? | (skipped when "No"; data is local only — Settings → Clear all saved data) |

Why "No": Google's definition of *collect* is data sent off the device by your app. History,
settings and favourites stay on the phone (shared_preferences). The rate request sends no user data.

## Government apps
**No.**

## Financial features
**My app doesn't provide any financial features.** (Loan/EMI, discount and tip are calculators;
the app gives no loans, payments, banking, crypto or trading.)

## Health
If Console asks about health features: the BMI tool is a plain calculator that shows the WHO
category. Pick the option saying the app has **no health features**. If you'd rather declare it,
choose the closest fitness/weight category. The app collects no health data either way.

## Advertising ID
**No**, the app does not use the advertising ID. (No ads SDK; the release manifest has no
`AD_ID` permission.)
