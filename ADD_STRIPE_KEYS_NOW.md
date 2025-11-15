# 🔑 Add Your Stripe Keys - Quick Guide

## ✅ You Have Your Live Publishable Key!

**Live Publishable Key:**
```
pk_live_51RMvqtLG1bcPbzSkidplQfw9WRtaCYKtwu4JCHQ0ELE03whKHrKgQ01GnYyEVNVdue3vlK7fMz386PJsg8uzyLPn00oybarVuz
```

## ⚠️ Still Need: Test Publishable Key

1. In Stripe Dashboard, toggle to **"Test mode"** (top right)
2. Go to: Developers → API keys
3. Copy the **Publishable key** (starts with `pk_test_51RMvr1...`)

---

## 📱 How to Add Keys to Your App

### **Option 1: Via App UI (Recommended)** ⭐

1. Run your app in debug mode:
   ```bash
   cd /Users/senaimotley/openslot
   flutter run
   ```

2. In your app, navigate to:
   - **Settings** → **Stripe Settings**

3. Enter both keys:
   - Test Publishable Key: `pk_test_...` (from test mode)
   - Live Publishable Key: `pk_live_51RMvqtLG1bcPbzSkidplQfw9WRtaCY...` (you have this!)

4. Tap **Save**

5. Keys are now stored securely! ✅

---

### **Option 2: Via Command Line**

If you prefer to add them via build commands:

**For development/testing:**
```bash
flutter run --dart-define=STRIPE_TEST_PUBLISHABLE_KEY=pk_test_YOUR_TEST_KEY
```

**For production builds:**
```bash
flutter build ios --release \
  --dart-define=STRIPE_LIVE_PUBLISHABLE_KEY=pk_live_51RMvqtLG1bcPbzSkidplQfw9WRtaCYKtwu4JCHQ0ELE03whKHrKgQ01GnYyEVNVdue3vlK7fMz386PJsg8uzyLPn00oybarVuz
```

---

## ✅ After Adding Keys

Test that payments work:

1. **Run app in debug mode** (uses test keys automatically)
2. **Find a paid event** or create one
3. **Try booking with test card:** `4242 4242 4242 4242`
   - Expiry: Any future date
   - CVC: Any 3 digits
4. **Check Stripe Dashboard** → Test payments

If the payment goes through, you're all set! 🎉

---

## 📊 Configuration Summary

| Key Type | Status | Value |
|----------|--------|-------|
| Test Secret Key | ✅ In Firebase | `sk_test_51RMvr1...` |
| Live Secret Key | ✅ In Firebase | `sk_live_51RMvqt...` |
| Test Publishable | ⚠️ Need to add | Get from test mode |
| Live Publishable | ✅ You have it! | `pk_live_51RMvqt...` |

---

## 🎯 Next Steps

1. ✅ Switch Stripe to Test mode
2. ✅ Copy test publishable key
3. ✅ Add both keys via app Settings
4. ✅ Test a payment with 4242 card
5. ✅ Move to Step 2: Android signing

---

**You're almost done with Step 1!** Just get that test key and add both to the app. 🚀

