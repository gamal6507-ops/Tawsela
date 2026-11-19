# Release verification — 2026-11-19

## Scope

Cash-only Flutter web release. Existing app kept on Flutter/Firebase; electronic payments, demo balances, fabricated drivers/ETAs and inactive promo success removed from production flows. Approved drivers can accept, start and finish rides. Operator approves drivers manually in Firebase after external identity/license review.

## Evidence

- Flutter regression suite: **30 tests passed**. Includes rapid booking confirmation, pending-create cancellation, recoverable failure, single completion acknowledgement, failed completion, driver-only arrival, rating persistence/failure, account-switch notification race, and numeric decoding.
- Firestore Standard emulator: **20 tests passed** using `demo-tawsela`. Covers unauthenticated access, ownership, quote tampering, driver approval/availability, atomic acceptance/cancellation, immutable receipt, full completion, chat sender spoofing, and rating ownership.
- Geocoding proxy: **3 Node tests passed**. Covers invalid methods/input, region parameters, caching/throttling, and explicit provider failure.
- `flutter analyze --no-pub --no-fatal-infos`: no errors or warnings; informational SDK deprecations remain. Flutter 3.50 deprecates legacy Material imports; migration is not included.
- Final release web build passed: `flutter build web --release --no-web-resources-cdn` (146.6 seconds).
- Dedicated live Firebase smoke check passed signup, profile write/read, sign-out and email sign-in. Synthetic test profile/account removed, and no email sent.
- Production Firebase project `tawsela-gamal6507`: Standard `(default)` DB in `nam5`, `freeTier: true`; rules, indexes and email/password auth deployed.
- Fresh independent source review found address lookup and notification account-switch races. Both were corrected; reviewer confirmed the fixes and found no further high-impact issue in its focused pass.
- Runtime Node dependencies: `npm audit --omit=dev` reported zero vulnerabilities. Development tooling is not included in Vercel runtime.

## Red/green history

The first booking regression run failed all three checks (double request, unhandled create error, search restarting after cancellation); they pass after the BLoC repair. Rating tests initially failed because persistence was absent. Notification account-switch test failed before UID capture/guards. Numeric/map decoding tests failed on integer doubles and gradient lists before conversion fixes.

## Practical limits

No store/mobile binaries tested. Android production signing must be provided by the operator. Google-only accounts are disabled until OAuth and provider-aware reauthentication are completed. No billing, payment processor, SMS, background push, automated driver verification, insured service or staffed support was provisioned. Public geocoding/tiles and free-tier quotas have availability and usage limits; coordinate selection is the lookup fallback. Receipts/history are not proof of cash collection. Prototype rules and retention policy require operator review before broad/commercial rollout.

## Publication

The [GitHub Actions release checks](https://github.com/gamal6507-ops/Tawsela/actions/runs/44501956075) passed for commit `511f552` on `main`. Vercel published this commit to [Tawsela](https://tawsela-kappa.vercel.app). The public homepage, Flutter bootstrap, main JavaScript bundle and nested route responded successfully. The geocoding API returned Cairo coordinates for a valid query and HTTP 400 for a one-character query. The public hostname was verified in Firebase Auth's authorized domains. These HTTP checks do not exercise a full two-user ride in a browser.
