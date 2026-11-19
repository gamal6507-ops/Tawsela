# Tawsela free-tier web release

The owner authorized implementation of the review findings and publication to the existing GitHub repository and Vercel. They have no payment provider or driver administration service and explicitly requested free services.

## Approach

Retain Flutter, Firebase Authentication, and Firestore. Use cash payment only, without simulated balances, cards, top-ups, discounts, or driver acceptance. Provide a driver workspace with registration pending manual approval in Firebase. Firestore Security Rules enforce ownership, driver approval, accepted transitions, and cash fares. No paid Cloud Functions or payment integration is required. Existing fake repositories remain test fixtures only.

Alternative considered: paid payment/dispatch backend; rejected because the owner requested free services. A demo-only website would not satisfy the request to fix actual bookings.

## Behavior

- Address text must resolve to an actual coordinate or be selected on the map. No Cairo fallback silently used as GPS. Display approximate straight-line distance/fare honestly; do not claim a road route or live ETA.
- Quote formula uses a deterministic coordinate-based approximate distance, shared with rules. Rider and approved driver agree to the displayed cash fare.
- A ride is accepted only by an approved available driver, and driver availability is atomically reserved. Rider cannot start or finish their own trip. Driver advances accepted -> in_progress -> arrived. Rider acknowledgement atomically stores an immutable trip by request ID and completes the request. No synthetic drivers.
- Persist active request ID and state using Firestore queries, not local cross-user state. Cancelled searches cannot become accepted. Clear all user-specific state at authentication changes.
- Ratings persist by trip ID and rider ownership. Notifications are per-user persisted inbox records. No push-delivery claims. Discounts stay unavailable until explicitly configured; no misleading success.
- Account changes distinguish contact email from authentication email. Provide password change, verified email change, verification, account deletion with reauthentication, support/privacy information, and honest unsupported states.
- Use manual public geocoding behind a Vercel endpoint with caching and rate limiting; no autocomplete or background geocoding. Map attribution remains visible.
- Provide web-safe Google sign-in, startup recovery, accessible loading/error/retry UI, tests, CI, deployment config, and operational documentation.

## External prerequisites

Firebase project access, database/rules deployment rights, and authorized web domain are required for live booking. Driver identity approval remains an operator responsibility. Free-tier usage quotas apply. No operational fleet, insurance, or 24/7 support is implied by the UI.

## Validation

Regression tests for booking submission deduplication, error propagation, cancellation, durable completion, rating, and account scoping. Firestore emulator tests exercise ownership and driver/rider state transitions. Run Flutter analysis/tests/release web build and verify deployed HTTP assets and routes. Publish only factual test results and disclose unavailable external prerequisites.
