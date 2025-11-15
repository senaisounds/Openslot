# 🚀 Quick Start: 3-Minute Customer Setup

## TL;DR - Just Run This:

```bash
cd /Users/senaimotley/openslot
./deploy_customer_function.sh
```

That's it! The script handles everything.

---

## What The Script Does:

1. ✅ Checks Firebase CLI installation
2. ✅ Builds TypeScript functions
3. ✅ Authenticates you with Firebase (opens browser)
4. ✅ Verifies project settings
5. ✅ Deploys the customer creation function
6. ✅ Tests the deployed function
7. ✅ Shows you the results

**Time Required**: 2-3 minutes

---

## Manual Steps (If Script Doesn't Work):

### Option A: Quick Deploy
```bash
cd /Users/senaimotley/openslot
firebase login --reauth
cd functions
firebase deploy --only functions:createStripeCustomer
```

### Option B: Step-by-Step
```bash
# 1. Navigate to project
cd /Users/senaimotley/openslot

# 2. Log in to Firebase (opens browser)
firebase login --reauth

# 3. Build functions
cd functions
npm run build

# 4. Deploy
firebase deploy --only functions:createStripeCustomer

# 5. Verify
curl -X POST https://us-central1-open-mic-5cc8e.cloudfunctions.net/createStripeCustomer \
  -H "Content-Type: application/json" \
  -d '{"userId": "test", "email": "test@example.com", "debug": true}'
```

---

## After Deployment:

### Test It:

1. **App should already be running** in simulator
2. **Make a payment**:
   - Open event with price
   - Click "Reserve"
   - Card: `4242 4242 4242 4242`
   - Expiry: `12/25`
   - CVC: `123`
   - ZIP: `12345`

3. **Watch terminal logs**:
   ```
   Got customer ID for payment: cus_XXXXXXXXXX
   ✅ Payment successful
   ```

4. **Verify in Stripe**:
   - Go to: https://dashboard.stripe.com/test/customers
   - See your new customer!

---

## Troubleshooting:

### "Command not found: firebase"
```bash
npm install -g firebase-tools
```

### "Authentication Error"
```bash
firebase login --reauth
```

### "Function not found (404)"
Function didn't deploy. Re-run:
```bash
cd /Users/senaimotley/openslot/functions
firebase deploy --only functions:createStripeCustomer
```

### "Stripe API Error"
Check Stripe keys are configured:
```bash
firebase functions:config:get
```

Should show:
```json
{
  "stripe": {
    "test_key": "sk_test_...",
    "live_key": "sk_live_..."
  }
}
```

If missing, set them:
```bash
firebase functions:config:set stripe.test_key="YOUR_TEST_KEY"
firebase functions:config:set stripe.live_key="YOUR_LIVE_KEY"
firebase deploy --only functions
```

---

## What Gets Fixed:

| Before | After |
|--------|-------|
| ❌ Invalid customer IDs | ✅ Valid customer IDs |
| ❌ Guest checkout only | ✅ Proper customer tracking |
| ❌ Payment errors | ✅ Smooth payments |
| ❌ No usage tracking | ✅ Full usage tracking |
| ❌ Can't save cards | ✅ Can save payment methods |

---

## Files Created:

1. `functions/src/index.ts` - Added `createStripeCustomer` function
2. `lib/api/stripe_customer_service.dart` - New service class
3. `lib/pages/event_details.dart` - Updated payment flow
4. `lib/pages/main_nav.dart` - Updated payment flow
5. `deploy_customer_function.sh` - This deployment script
6. `STRIPE_CUSTOMER_SETUP_COMPLETE.md` - Full documentation
7. `QUICK_START_CUSTOMER_SETUP.md` - This file!

---

## Success Checklist:

- [ ] Deployment script runs without errors
- [ ] Function shows as deployed in Firebase Console
- [ ] Test payment creates customer in Stripe
- [ ] Customer ID stored in Firestore
- [ ] Terminal logs show "Got customer ID"
- [ ] No more "invalid customer" errors

---

## Ready? Let's Go!

```bash
cd /Users/senaimotley/openslot
./deploy_customer_function.sh
```

**That's literally all you need to do!** 🎉

---

**Questions?** Check the full documentation:
```bash
cat STRIPE_CUSTOMER_SETUP_COMPLETE.md
```

**Still stuck?** Check Firebase function logs:
```bash
firebase functions:log --only createStripeCustomer
```

