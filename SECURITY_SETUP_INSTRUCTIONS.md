# 🔐 Security Setup Instructions

## CRITICAL: Stripe Keys Configuration

### ⚠️ IMPORTANT SECURITY NOTICE
Your Stripe keys have been removed from the codebase for security. You MUST configure them properly before deployment.

## Step 1: Revoke Compromised Keys
1. Go to your [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
2. **IMMEDIATELY REVOKE** these compromised keys:
   - Test: `sk_test_51RMvr1Q0wBFV119bcCWvuYTtuA28bN7iS2xWZTs02TJdiv1psjISAR75RCsWJtGrlYGw8VCEzNJazTehBETO8WJf00Yyvmjcky`
   - Live: `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`
3. Generate new keys

## Step 2: Configure Firebase Functions (Server-Side)
```bash
# Set Stripe keys in Firebase config
firebase functions:config:set stripe.test_key="sk_test_YOUR_NEW_TEST_KEY"
firebase functions:config:set stripe.live_key="sk_live_YOUR_NEW_LIVE_KEY"

# Deploy the updated functions
firebase deploy --only functions
```

## Step 3: Configure Client-Side Keys (Flutter)
Add these to your build arguments or environment:

### For Flutter Build:
```bash
# Test build
flutter build ios --dart-define=STRIPE_TEST_PUBLISHABLE_KEY=pk_test_YOUR_TEST_KEY

# Production build
flutter build ios --dart-define=STRIPE_LIVE_PUBLISHABLE_KEY=pk_live_YOUR_LIVE_KEY
```

### Alternative: Update dart_defines in your IDE
Add to your run configurations:
```
--dart-define=STRIPE_TEST_PUBLISHABLE_KEY=pk_test_YOUR_TEST_KEY
--dart-define=STRIPE_LIVE_PUBLISHABLE_KEY=pk_live_YOUR_LIVE_KEY
```

## Step 4: Verify Configuration
1. Test payment flow in debug mode
2. Verify no hardcoded keys remain in code
3. Check Firebase Functions logs for proper key loading

## Security Best Practices Applied
✅ **Secret keys removed** from client code  
✅ **Environment variables** implemented  
✅ **Password logging** removed from Cloud Functions  
✅ **Debug credentials** removed  
✅ **Placeholder keys** replaced with environment lookups  

## Files Modified for Security
- `functions/src/index.ts` - Stripe keys now from environment
- `lib/api/stripe_config.dart` - Keys from environment variables
- `lib/config/stripe_production.dart` - Removed hardcoded secret key
- `lib/pages/login_page.dart` - Removed debug credentials

## Next Steps
1. Set up your CI/CD to include proper environment variables
2. Consider using Firebase Remote Config for publishable keys
3. Implement key rotation strategy
4. Monitor for any remaining hardcoded secrets

⚠️ **DO NOT COMMIT ACTUAL KEYS TO VERSION CONTROL**
