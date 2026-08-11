# P0 Security Fixes

Implemented on branch `cursor/full-project-analysis` (or follow-up security branch).

## What changed

### Cloud Functions (`functions/src/`)
- Added `http_auth.ts` with Firebase ID token verification, admin helper, server-side Stripe mode resolution
- **Auth required** on: `verifyEventPassword`, `reserveAction`, `deleteEvent`, `createPaymentIntent`, `getEphemeralKey`, `createStripeCustomer`, `reportStripeUsage`
- `reserveAction` uses **token UID only** (ignores body `userID`); private events require **password re-check** (ignores `passwordVerified`)
- `deleteEvent` requires host or admin
- Stripe customer / ephemeral key / usage bound to authenticated user's Firestore customer ID
- Stripe mode from `stripe.mode` / `STRIPE_MODE` only (defaults to **test**; set `live` for production)
- Admin checks **re-enabled** on `reviewReport`, `getPendingReports`, `getReviewedReports`
- Password values **never logged**
- `reportContent` always uses `context.auth.uid` as reporter

### Firestore rules
- Client self-join limited to **public free** events (private/paid via Functions)
- Users can read their own `admins/{uid}` doc
- Explicit rules for `reports`, `stripe_usage`, `paymentMethods`, `bankVerifications`, `payouts`

### Flutter client
- `FunctionsHttpClient` attaches `Authorization: Bearer <idToken>`
- All HTTP Function call sites updated
- `_debug = true` removed; emulator opt-in via `--dart-define=USE_FIREBASE_EMULATOR=true`
- `EnvironmentConfig` production-safe defaults
- Profile admin UI uses Firestore `admins` collection (not hardcoded emails)
- Local password dialog no longer compares a client-side `correctPassword`

## Deploy checklist

```bash
# 1) Ensure admin docs exist for moderator UIDs
# Firestore: admins/{uid} => { isAdmin: true }

# 2) Stripe mode for this Functions deploy
firebase functions:config:set stripe.mode="test"   # or "live" for production
# keys should already be set:
# firebase functions:config:set stripe.test_key="sk_test_..." stripe.live_key="sk_live_..."

# 3) Deploy functions + rules
cd functions && npm run build
firebase deploy --only functions,firestore:rules

# 4) App release builds
flutter build ios --dart-define=PRODUCTION=true
# Test Stripe in debug builds is automatic (kDebugMode)
# Force test Stripe in profile/release: --dart-define=DEBUG_STRIPE=true
```

## Still open (P1+)
- Bind PaymentIntent success to seat grant (webhooks)
- Hash event passwords / stop storing plaintext on public event docs
- App Check + rate limiting on password verify
- Refunds on unreserve
- Transactions for capacity
