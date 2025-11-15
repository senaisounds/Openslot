# Stripe Usage Tracking - Deployment Guide

## ✅ What Was Implemented

### New Files Created:
1. **`lib/api/stripe_usage_tracker.dart`** - Client-side usage tracking service
2. **`functions/src/index.ts`** (updated) - Firebase Function for reporting to Stripe

### Modified Files:
1. **`lib/pages/event_details.dart`** - Added usage tracking after successful bookings
2. **`lib/pages/main_nav.dart`** - Added usage tracking after successful bookings

---

## 🚀 How to Deploy

### Step 1: Deploy Firebase Functions

```bash
cd /Users/senaimotley/openslot/functions

# Build TypeScript
npm run build

# Deploy the new reportStripeUsage function
firebase deploy --only functions:reportStripeUsage
```

**Expected Output:**
```
✔  functions[reportStripeUsage(us-central1)]: Successful create operation.
Function URL (reportStripeUsage): https://us-central1-open-mic-5cc8e.cloudfunctions.net/reportStripeUsage
```

### Step 2: Test the Firebase Function

```bash
curl -X POST https://us-central1-open-mic-5cc8e.cloudfunctions.net/reportStripeUsage \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "cus_test123",
    "eventName": "booking_completed",
    "quantity": 1,
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'",
    "metadata": {
      "event_id": "test_event",
      "booking_id": "test_booking",
      "amount": 0.99
    },
    "debug": true
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "id": "evt_...",
  "message": "Usage reported successfully"
}
```

### Step 3: Hot Restart Your App

```bash
# In your terminal where the app is running
# Press: R (capital R)
```

---

## 🧪 How to Test

### Test 1: Manual Test Function

```dart
// Add this to a test button in your app
ElevatedButton(
  onPressed: () async {
    final success = await StripeUsageTracker.testUsageReporting(
      customerId: slottedUser.customerID ?? 'test_customer',
      debug: true,
    );
    
    print(success ? '✅ Usage tracking works!' : '❌ Usage tracking failed');
  },
  child: Text('Test Usage Tracking'),
)
```

### Test 2: Real Booking Flow

1. Run app on iOS/Android device (Stripe doesn't work on web)
2. Navigate to a paid event ($0.99 or more)
3. Click "Reserve Slot"
4. Complete payment with test card: `4242 4242 4242 4242`
5. Check logs for:
   ```
   Reporting booking to Stripe meter: booking_xxx
   Usage reported successfully: evt_xxx
   ```
6. Verify in Stripe Dashboard → Billing → Meters
7. You should see the "booking_completed" event appear

### Test 3: Check Firestore

After a successful booking, check Firestore collection `stripe_usage`:

```json
{
  "customerId": "cus_xxx",
  "eventName": "booking_completed",
  "quantity": 1,
  "timestamp": "2025-10-24T...",
  "metadata": {
    "event_id": "event_xxx",
    "booking_id": "booking_xxx",
    "amount": 0.99
  },
  "stripeEventId": "evt_xxx",
  "createdAt": "...",
  "debug": true
}
```

---

## 📊 Monitoring

### Check Usage in Stripe Dashboard

1. Go to https://dashboard.stripe.com
2. Click **Billing** → **Meters**
3. Click on **"Event Bookings"** meter
4. You should see usage events appearing in real-time

### Check Firestore Logs

```javascript
// In Firestore console
db.collection('stripe_usage')
  .orderBy('createdAt', 'desc')
  .limit(10)
  .get()
```

### Check Firebase Function Logs

```bash
firebase functions:log --only reportStripeUsage
```

---

## 🔍 Troubleshooting

### Issue 1: "No customer ID available"

**Symptom:** Log shows "No customer ID available - usage tracking skipped"

**Cause:** User doesn't have a Stripe customer ID

**Solution:**
1. Check if user has `customerID` or `testCustomerID` in Firestore
2. User might need to create a Stripe customer account first
3. Add customer creation flow if missing

### Issue 2: "Failed to report usage to Stripe"

**Symptom:** HTTP error from Firebase Function

**Cause:** Invalid parameters or Stripe API error

**Solution:**
1. Check Firebase Function logs: `firebase functions:log`
2. Verify customer ID format (must start with `cus_`)
3. Verify Stripe keys are configured correctly
4. Check if meter name matches: `booking_completed`

### Issue 3: "MissingPluginException"

**Symptom:** Plugin error on web

**Cause:** Running on web where Stripe doesn't work

**Solution:**
- Usage tracking only works on iOS/Android
- Web platform automatically skips Stripe operations

### Issue 4: Usage not appearing in Stripe Dashboard

**Symptom:** Function succeeds but no usage in dashboard

**Possible Causes:**
1. Wrong Stripe account (check test vs live mode)
2. Meter name mismatch (must be exactly `booking_completed`)
3. Customer ID doesn't exist in Stripe
4. Using test key but checking live dashboard (or vice versa)

**Solution:**
1. Verify you're in the correct mode (test/live) in Stripe Dashboard
2. Check meter event name matches exactly
3. Verify customer exists: `stripe customers retrieve cus_xxx`

---

## 🎯 Success Criteria

✅ **Firebase Function deployed successfully**
✅ **Test curl request returns success**
✅ **App hot restarted without errors**
✅ **Test booking creates usage event**
✅ **Usage appears in Stripe Dashboard**
✅ **Usage stored in Firestore collection**

---

## 📈 What Happens Next

### Automatic Billing

Stripe will now automatically:
1. Track every booking via the meter
2. Calculate usage at end of billing period
3. Charge customer $0.99 per booking
4. Send invoices automatically
5. Handle payment collection

### Your Billing Dashboard

Monitor in Stripe Dashboard:
- **Billing → Meters** - See usage events
- **Billing → Subscriptions** - See customer usage
- **Payments** - See generated invoices
- **Reports** - Download usage reports

---

## 🔐 Security Notes

✅ **What's Secure:**
- Customer IDs validated on backend
- Stripe secret keys only on backend
- CORS properly configured
- Usage stored in Firestore for audit

⚠️ **What to Monitor:**
- Rate limiting (currently not implemented)
- Duplicate event prevention (currently not implemented)
- Failed usage report retry (currently not implemented)

---

## 🚀 Next Steps

### Recommended Enhancements:

1. **Add Idempotency** (Prevent duplicate charges)
   ```typescript
   // In Firebase Function
   const usageRecord = await stripe.billing.meterEvents.create({
     event_name: eventName,
     payload: { ... },
     idempotency_key: `booking_${bookingId}`, // Prevents duplicates
   });
   ```

2. **Add Retry Logic** (Handle temporary failures)
   ```dart
   // In client
   for (int attempt = 0; attempt < 3; attempt++) {
     final success = await StripeUsageTracker.reportBookingCompleted(...);
     if (success) break;
     await Future.delayed(Duration(seconds: Math.pow(2, attempt)));
   }
   ```

3. **Add Webhook Handler** (Verify usage from Stripe side)
   ```typescript
   export const stripeUsageWebhook = functions.https.onRequest(async (req, res) => {
     // Verify webhook signature
     // Handle billing.meter.error_report_triggered
     // Notify admin if usage tracking fails
   });
   ```

4. **Add Analytics** (Track usage patterns)
   ```dart
   FirebaseAnalytics.instance.logEvent(
     name: 'usage_reported',
     parameters: {
       'booking_id': bookingId,
       'amount': amount,
       'customer_id': customerId,
     },
   );
   ```

---

## 📞 Support

If usage tracking fails:
1. Check Firebase logs: `firebase functions:log`
2. Check Stripe Dashboard for errors
3. Verify meter configuration in Stripe
4. Contact Stripe support if needed

---

*Deployment Date: 2025-10-24*  
*Next Review: After first production booking*

