# 🔐 Security Setup Instructions

## Stripe Keys Configuration Status

### ✅ CURRENT STATUS
Your Stripe keys are securely configured and ready for production.

## Step 1: Server-Side Keys (Firebase Functions)
✅ **ALREADY CONFIGURED** - Your secret keys are set in Firebase Functions config:
- Test Secret Key: `sk_test_51RMvr1Q0wBFV119b...` ✅
- Live Secret Key: `sk_live_51RMvqtLG1bcPbzSk...` ✅

To view current configuration:
```bash
firebase functions:config:get
```

To update keys (if needed in the future):
```bash
# Update Stripe keys in Firebase config (only if changing keys)
firebase functions:config:set stripe.test_key="sk_test_YOUR_KEY"
firebase functions:config:set stripe.live_key="sk_live_YOUR_KEY"

# Deploy the updated functions
firebase deploy --only functions
```

## Step 2: Client-Side Keys (Flutter)
⚠️ **ACTION REQUIRED** - You need to add your publishable keys.

Get your publishable keys from: https://dashboard.stripe.com/apikeys

They should match your secret keys:
- Test Publishable: `pk_test_51RMvr1Q0wBFV119b...` (starts with same number)
- Live Publishable: `pk_live_51RMvqtLG1bcPbzSk...` (starts with same number)

### Method 1: Via Stripe Settings Page (Recommended)
1. Run your app in debug mode
2. Go to Settings → Stripe Settings
3. Enter your publishable keys
4. They'll be stored securely in the app

### Method 2: Via Build Arguments
```bash
# Test/Debug build
flutter run --dart-define=STRIPE_TEST_PUBLISHABLE_KEY=pk_test_YOUR_KEY

# Production build
flutter build ios --release --dart-define=STRIPE_LIVE_PUBLISHABLE_KEY=pk_live_YOUR_KEY
```

### Method 3: Via IDE Run Configuration
Add to your run configurations in VS Code or Android Studio:
```
--dart-define=STRIPE_TEST_PUBLISHABLE_KEY=pk_test_YOUR_KEY
--dart-define=STRIPE_LIVE_PUBLISHABLE_KEY=pk_live_YOUR_KEY
```

## Step 3: Verify Configuration
1. Test payment flow in debug mode
2. Verify no hardcoded keys remain in code
3. Check Firebase Functions logs for proper key loading

## Security Best Practices ✅
✅ **Secret keys secured** in Firebase Functions (server-side only)  
✅ **Environment variables** implemented for publishable keys  
✅ **Secure storage** used for client-side key caching  
✅ **No hardcoded keys** in version control  
✅ **Test/Live mode** switching automated based on debug flag  

## Key Management Best Practices
- 🔒 **Secret keys (sk_...)** - Only on server (Firebase Functions)
- 🔓 **Publishable keys (pk_...)** - Safe for client-side use
- 🚫 **Never commit keys** to version control
- 🔄 **Rotate keys** if ever exposed or every 90 days
- 📊 **Monitor usage** in Stripe Dashboard for anomalies

## Files Using Stripe Configuration
- `functions/src/index.ts` - Server-side payment processing
- `lib/api/stripe_config.dart` - Client-side key management
- `lib/config/stripe_production.dart` - Production configuration
- `lib/pages/stripe_settings_page.dart` - User key configuration UI

## Troubleshooting
**Issue:** Payment fails with "Invalid API key"
- **Solution:** Check Firebase Functions config with `firebase functions:config:get`

**Issue:** Keys not found in app
- **Solution:** Set publishable keys via Stripe Settings page or dart-define

**Issue:** Test mode not working
- **Solution:** Ensure you're using pk_test_ keys for debug builds

## Next Steps
1. ✅ Server keys are configured in Firebase Functions
2. ⚠️ Add publishable keys (see Step 2 above)
3. ⏭️ Test payment flow in debug mode
4. ⏭️ Deploy to production when ready

**Current Status:** Server-side ready ✅ | Client-side needs publishable keys ⚠️
