# 🧪 Testing Guide: Stripe Customer Creation

## Test Checklist

### ✅ Pre-Deployment Tests (Current State)

**Test 1: Payment Without Customer ID** (Guest Checkout)
- [x] App builds and runs
- [x] Payment sheet appears
- [x] Test card works: `4242 4242 4242 4242`
- [x] Payment processes successfully
- [x] Booking confirmed
- [x] **Expected**: "Failed to create customer, proceeding with guest checkout"

**Status**: ✅ PASSING (You already tested this!)

---

### 🚀 Post-Deployment Tests (After Function Deployment)

#### Test 2: Automatic Customer Creation

**Steps**:
1. Deploy function: `./deploy_customer_function.sh`
2. Hot restart app (press `R` in terminal)
3. Make a payment on any event
4. Watch terminal logs

**Expected Logs**:
```
Got customer ID for payment: cus_XXXXXXXXXX
Created new Stripe customer: cus_XXXXXXXXXX
✅ Payment successful
```

**Verification**:
- Go to https://dashboard.stripe.com/test/customers
- See new customer with your email

**Pass Criteria**:
- ✅ No errors in logs
- ✅ Customer ID appears
- ✅ Payment succeeds
- ✅ Customer in Stripe Dashboard

---

#### Test 3: Customer ID Reuse

**Steps**:
1. Make a second payment (after Test 2)
2. Watch terminal logs

**Expected Logs**:
```
Got customer ID for payment: cus_XXXXXXXXXX
(Same ID as before!)
✅ Payment successful
```

**Verification**:
- Check Stripe Dashboard
- Only ONE customer should exist
- Customer should have multiple payments

**Pass Criteria**:
- ✅ Same customer ID used
- ✅ No duplicate customers created
- ✅ Payment succeeds

---

#### Test 4: Invalid Customer ID Cleanup

**Setup**:
1. Manually add invalid customer ID to Firestore
2. Or use existing user with invalid ID

**Steps**:
1. Make a payment
2. Watch terminal logs

**Expected Logs**:
```
Existing customer ID cus_invalid is invalid, creating new one
Got customer ID for payment: cus_YYYYYYYYYY
(New valid ID)
✅ Payment successful
```

**Verification**:
- Check Firestore: Old ID replaced with new one
- Check Stripe: New customer exists

**Pass Criteria**:
- ✅ Invalid ID detected
- ✅ New customer created
- ✅ Firestore updated
- ✅ Payment succeeds

---

### 📊 Test Scenarios Matrix

| Scenario | Before Deployment | After Deployment |
|----------|------------------|------------------|
| **New User, No Customer ID** | Guest checkout | Customer created |
| **Existing Valid Customer ID** | Guest checkout | Customer reused |
| **Invalid Customer ID** | Error → Guest checkout | Auto-fixed → Customer created |
| **Network Error** | Guest checkout | Guest checkout (fallback) |

---

## Test Cards

### Successful Payments
```
Card: 4242 4242 4242 4242
Exp:  12/25
CVC:  123
ZIP:  12345
```

### Requires Authentication (3D Secure)
```
Card: 4000002500003155
Exp:  12/25
CVC:  123
ZIP:  12345
```

### Declined - Insufficient Funds
```
Card: 4000000000009995
Exp:  12/25
CVC:  123
ZIP:  12345
```

---

## Monitoring & Debugging

### Check Logs

**App Logs** (Terminal where app is running):
```
flutter: Got customer ID for payment: cus_...
flutter: Payment successful
```

**Function Logs** (Firebase):
```bash
firebase functions:log --only createStripeCustomer
```

**Expected Output**:
```
Creating Stripe customer for user abc123 (debug: true)
Created new Stripe customer: cus_XXXXXXXXXX
Updated Firestore user abc123 with customer ID: cus_XXXXXXXXXX
```

---

### Check Firestore

**Firebase Console** → Firestore Database → `users` collection

**Before**:
```json
{
  "id": "user123",
  "email": "test@example.com",
  "customerID": null,  // or invalid
  "test-customerID": null
}
```

**After First Payment**:
```json
{
  "id": "user123",
  "email": "test@example.com",
  "test-customerID": "cus_XXXXXXXXXX",
  "test-customerID_created": "2025-11-12T16:30:00Z"
}
```

---

### Check Stripe Dashboard

**Test Mode**: https://dashboard.stripe.com/test/customers

**What to Look For**:
- Customer email matches user
- Metadata includes `firebaseUID`
- Payment history shows test payments
- Customer ID matches Firestore

---

## Error Scenarios & Solutions

### Error 1: "Failed to create customer: 404"

**Cause**: Function not deployed

**Solution**:
```bash
./deploy_customer_function.sh
```

---

### Error 2: "Failed to create customer: No such customer"

**Cause**: Using invalid existing customer ID

**Expected**: Should auto-create new customer

**If Not Working**: Run cleanup script
```bash
node scripts/cleanup_invalid_customers.js --dry-run
node scripts/cleanup_invalid_customers.js  # Apply changes
```

---

### Error 3: "Authentication Error"

**Cause**: Firebase credentials expired

**Solution**:
```bash
firebase login --reauth
```

---

### Error 4: Payment succeeds but no customer created

**Check**:
1. Function deployed? `firebase functions:list`
2. Function logs: `firebase functions:log --only createStripeCustomer`
3. Stripe keys configured? `firebase functions:config:get`

**Solution**:
```bash
# Set Stripe keys
firebase functions:config:set stripe.test_key="sk_test_YOUR_KEY"
firebase functions:config:set stripe.live_key="sk_live_YOUR_KEY"

# Re-deploy
firebase deploy --only functions:createStripeCustomer
```

---

## Performance Tests

### Test 5: Customer Creation Speed

**Measure**:
- Time from "Reserve" click to payment sheet appearing
- Time from payment to booking confirmation

**Expected**:
- Customer creation: < 2 seconds
- Total payment flow: < 10 seconds

**If Slow**: Check function logs for errors

---

### Test 6: Multiple Concurrent Payments

**Steps**:
1. Have 2+ test users
2. Make payments simultaneously
3. Verify no race conditions

**Pass Criteria**:
- ✅ Each user gets unique customer ID
- ✅ No duplicate customers
- ✅ All payments succeed

---

## Automated Testing

### Unit Test: Customer Service

```dart
// test/stripe_customer_service_test.dart
test('createOrGetCustomer creates new customer', () async {
  final customerId = await StripeCustomerService.createOrGetCustomer(
    userId: 'test_user',
    email: 'test@example.com',
    debug: true,
  );
  
  expect(customerId, startsWith('cus_'));
});

test('createOrGetCustomer reuses existing customer', () async {
  // First call
  final customerId1 = await StripeCustomerService.createOrGetCustomer(
    userId: 'test_user',
    email: 'test@example.com',
    debug: true,
  );
  
  // Second call
  final customerId2 = await StripeCustomerService.createOrGetCustomer(
    userId: 'test_user',
    email: 'test@example.com',
    debug: true,
  );
  
  expect(customerId1, equals(customerId2));
});
```

---

## Production Readiness Checklist

Before going live:

- [ ] All tests pass with test keys
- [ ] Switch to live Stripe keys
- [ ] Test on real iOS device
- [ ] Test with real credit card (small amount)
- [ ] Verify customer in live Stripe Dashboard
- [ ] Test refund process
- [ ] Set up Stripe webhooks
- [ ] Configure monitoring alerts
- [ ] Document customer support process
- [ ] Test edge cases (network failures, etc.)

---

## Success Metrics

### Key Indicators:

**Customer Creation Rate**:
- Target: 100% of paid bookings create customers
- Measure: Compare bookings to new customers

**Customer Reuse Rate**:
- Target: 80%+ users use existing customer ID
- Measure: Customer creation calls vs payment calls

**Error Rate**:
- Target: < 1% failures
- Measure: Failed customer creation / total attempts

**Performance**:
- Target: < 2 seconds for customer creation
- Measure: Average function execution time

---

## Monitoring Dashboard

**Key Metrics to Track**:
1. Customer creation success rate
2. Invalid customer ID detection rate
3. Function execution time
4. Payment success rate with vs without customers
5. Stripe API error rate

**Tools**:
- Firebase Console → Functions → Metrics
- Stripe Dashboard → Developers → Logs
- Custom logging in app

---

## Summary

### Quick Test Flow:

1. ✅ **Deploy**: `./deploy_customer_function.sh`
2. ✅ **Test Payment**: Use test card `4242 4242 4242 4242`
3. ✅ **Verify Logs**: See "Got customer ID: cus_..."
4. ✅ **Check Stripe**: Customer appears in dashboard
5. ✅ **Test Again**: Same customer ID reused

**Total Time**: 5 minutes

---

**Ready to test? Start here:**
```bash
./deploy_customer_function.sh
```

**Need help?** Check:
- `STRIPE_CUSTOMER_SETUP_COMPLETE.md` - Full docs
- `QUICK_START_CUSTOMER_SETUP.md` - Quick reference
- Firebase function logs - Error details

