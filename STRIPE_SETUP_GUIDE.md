# Stripe Payment Setup Guide

This guide will help you configure Stripe payments in your OpenSlot app.

## Quick Start

### Step 1: Get Your Stripe API Keys

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
2. Sign in or create an account
3. You'll see two types of keys:
   - **Publishable key** (starts with `pk_test_` or `pk_live_`)
   - **Secret key** (starts with `sk_test_` or `sk_live_`)

⚠️ **Important**: You only need the **publishable keys** (pk_test_ or pk_live_) for the mobile app.

### Step 2: Configure Keys in Your App

You have **3 options** to configure your Stripe keys:

#### Option A: Use the In-App Settings (Easiest) ✅

1. Run your app
2. Navigate to **Settings** → **Stripe Settings** (you'll need to add this to your settings page)
3. Enter your test key (`pk_test_...`)
4. Enter your live key (`pk_live_...`) when ready for production
5. Tap **Save Keys**

#### Option B: Use Environment Variables

Add these to your shell profile (`~/.zshrc` or `~/.bash_profile`):

```bash
export STRIPE_TEST_PUBLISHABLE_KEY="pk_test_YOUR_KEY_HERE"
export STRIPE_LIVE_PUBLISHABLE_KEY="pk_live_YOUR_KEY_HERE"
```

Then run with environment variables:

```bash
# For iOS
flutter run --dart-define=STRIPE_TEST_PUBLISHABLE_KEY=$STRIPE_TEST_PUBLISHABLE_KEY

# For Android
flutter run --dart-define=STRIPE_TEST_PUBLISHABLE_KEY=$STRIPE_TEST_PUBLISHABLE_KEY
```

#### Option C: Use the Setup Script

Run the interactive setup script:

```bash
dart run scripts/setup_stripe_keys.dart
```

Follow the prompts and then add the generated code to your app initialization.

## Testing Payments

### Test Mode Keys (pk_test_...)

When using test keys, you can use Stripe's test card numbers:

- **Success**: `4242 4242 4242 4242`
- **Decline**: `4000 0000 0000 0002`
- **3D Secure**: `4000 0025 0000 3155`

Use any:
- Future expiry date (e.g., 12/25)
- Any 3-digit CVC
- Any 5-digit ZIP code

## Production Setup

### Before Going Live:

1. **Get Live Keys**: Switch from test keys (`pk_test_`) to live keys (`pk_live_`)
2. **Configure Webhook**: Set up webhook endpoint in Stripe Dashboard
3. **Update Apple Merchant ID**: Verify `merchant.com.openslot.app` in Apple Developer
4. **Test Thoroughly**: Test all payment flows with real cards in test mode first
5. **Enable 3D Secure**: Recommended for fraud protection

### Apple Pay Setup (iOS)

Your app is already configured with:
- Merchant ID: `merchant.com.openslot.app`

Make sure this is registered in your Apple Developer account:
1. Go to [Apple Developer - Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Create/verify the Merchant ID: `merchant.com.openslot.app`
3. Upload your Stripe certificate

## Troubleshooting

### Warning: "No Stripe key configured"

This means no valid Stripe key was found. Follow **Step 2** above to configure keys.

### Error: "Invalid publishable key"

- Test keys must start with `pk_test_`
- Live keys must start with `pk_live_`
- Make sure there are no extra spaces

### Payment Failed

- Check your Stripe Dashboard for error details
- Verify your secret key matches your publishable key (test with test, live with live)
- Check your Firebase Functions are deployed correctly

### Apple Pay Not Working

1. Verify merchant ID in Apple Developer
2. Check Stripe account has Apple Pay enabled
3. Test on a real device (not simulator)
4. Verify you have a payment card added to Wallet

## Security Best Practices

✅ **DO:**
- Store publishable keys in secure storage
- Use test keys for development
- Use environment variables in CI/CD
- Rotate keys regularly
- Keep test and live keys separate

❌ **DON'T:**
- Commit keys to version control
- Share keys publicly
- Use live keys in development
- Store secret keys in the app (backend only!)

## Need Help?

- [Stripe Documentation](https://stripe.com/docs)
- [Stripe Support](https://support.stripe.com/)
- [OpenSlot Support](mailto:support@openslot.com)

## Current Configuration

Your app uses:
- `StripeConfig` class for key management
- Secure storage for key persistence
- Automatic test/live key switching based on debug mode
- Support for Apple Pay and Google Pay
- Integrated with Firebase Functions for backend processing


