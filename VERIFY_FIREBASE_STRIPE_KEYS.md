# 🔑 Verify Firebase Stripe Keys Setup

## Step 1: Login to Firebase

Open Terminal and run:

```bash
cd /Users/senaimotley/openslot/functions
firebase login --reauth
```

This will:
1. Open your browser
2. Ask you to select your Google account
3. Grant Firebase CLI access
4. Return to terminal when done

---

## Step 2: Check Current Configuration

After logging in, run:

```bash
firebase functions:config:get
```

**What you should see:**
```json
{
  "stripe": {
    "test_key": "sk_test_...",
    "live_key": "sk_live_..."
  }
}
```

**If you see both keys** → ✅ You're good! Skip to Step 4.

**If missing or empty** → ⚠️ Continue to Step 3.

---

## Step 3: Set Stripe Secret Keys (If Missing)

You need to set BOTH test and live **SECRET keys** (not publishable keys!).

### Get Your Secret Keys from Stripe:

1. Go to: https://dashboard.stripe.com/apikeys
2. You'll see TWO keys per mode:
   - **Publishable key** (pk_test_... or pk_live_...) - Already in your app ✅
   - **Secret key** (sk_test_... or sk_live_...) - Need these for Firebase! ⚠️

### Set Test Secret Key:

```bash
firebase functions:config:set stripe.test_key="sk_test_YOUR_SECRET_KEY_HERE"
```

Replace `sk_test_YOUR_SECRET_KEY_HERE` with your actual test secret key from Stripe.

### Set Live Secret Key:

**⚠️ IMPORTANT: This is for REAL payments!**

```bash
firebase functions:config:set stripe.live_key="sk_live_YOUR_SECRET_KEY_HERE"
```

Replace `sk_live_YOUR_SECRET_KEY_HERE` with your actual live secret key from Stripe.

---

## Step 4: Deploy Functions

After setting the keys, you MUST redeploy:

```bash
firebase deploy --only functions
```

This takes 3-5 minutes.

---

## Step 5: Verify Keys Are Working

### Check Configuration Again:

```bash
firebase functions:config:get
```

Should show:
```json
{
  "stripe": {
    "test_key": "sk_test_51...",
    "live_key": "sk_live_51..."
  }
}
```

---

## 🎯 Quick Reference

### Keys You Need:

| Location | Type | Key Format | Purpose |
|----------|------|------------|---------|
| **App (Stripe Settings)** | Publishable | `pk_test_...` | Test mode - in app |
| **App (Stripe Settings)** | Publishable | `pk_live_...` | Live mode - in app |
| **Firebase Functions** | Secret | `sk_test_...` | Test mode - backend |
| **Firebase Functions** | Secret | `sk_live_...` | Live mode - backend |

### Where to Find Keys:

**Stripe Dashboard:** https://dashboard.stripe.com/apikeys

**Test Mode:**
- Toggle to "Test mode" (top right)
- Copy "Secret key" (starts with `sk_test_`)
- Copy "Publishable key" (starts with `pk_test_`) - Already have this ✅

**Live Mode:**
- Toggle to "Live mode" (top right)
- Copy "Secret key" (starts with `sk_live_`)
- Copy "Publishable key" (starts with `pk_live_`) - Already have this ✅

---

## 🚨 Security Notes

### ⚠️ NEVER:
- ❌ Put secret keys in your app code
- ❌ Commit secret keys to Git
- ❌ Share secret keys publicly

### ✅ ALWAYS:
- ✅ Keep secret keys in Firebase Functions config only
- ✅ Keep publishable keys in app (safe to be public)
- ✅ Use environment variables or secure config

---

## ✅ Verification Checklist

Before going live, verify:

- [ ] Logged into Firebase CLI
- [ ] `firebase functions:config:get` shows both test_key and live_key
- [ ] Both keys start with `sk_test_` and `sk_live_`
- [ ] Functions deployed after setting keys
- [ ] App has publishable keys saved (pk_test_ and pk_live_)
- [ ] Test payment works in debug mode
- [ ] Ready to test live payment in TestFlight

---

## 🧪 Test Your Setup

### Test Mode (Debug):
1. Run app from Xcode
2. Create event with price
3. Try to pay with: `4242 4242 4242 4242`
4. Should succeed ✅
5. Check Stripe Dashboard (Test mode) for payment

### Live Mode (Production):
**⚠️ ONLY TEST THIS IN TESTFLIGHT WITH REAL CARD (will charge real money!)**

1. Install app from TestFlight
2. Create event with price
3. Use real credit card
4. Should succeed ✅
5. Check Stripe Dashboard (Live mode) for payment
6. You'll see real money in your Stripe account!

---

## 💡 Common Issues

### "Missing required parameters"
- **Cause**: Secret keys not set in Firebase
- **Fix**: Run `firebase functions:config:set` commands

### "Authentication Error"
- **Cause**: Not logged into Firebase CLI
- **Fix**: Run `firebase login --reauth`

### "Invalid API Key"
- **Cause**: Wrong key or typo
- **Fix**: Double-check you copied the SECRET key (sk_...) not publishable key (pk_...)

### "Function not found"
- **Cause**: Functions not deployed after setting config
- **Fix**: Run `firebase deploy --only functions`

---

## 📞 Need Help?

If you see errors:
1. Copy the exact error message
2. Check which step failed
3. Verify you used correct key format (sk_test_ or sk_live_)
4. Make sure functions are deployed

---

**Good luck!** 🚀

