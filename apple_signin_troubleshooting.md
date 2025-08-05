# Apple Sign In Troubleshooting Guide

## Current Error
```
[firebase_auth/invalid-credential] Invalid OAuth response from apple.com
```

## Configuration Check

### 1. Apple Developer Console Configuration
**Service ID:** `com.openslot.app.service`
**Team ID:** `4GCYNC6WXK`
**Key ID:** `K84396S22D` (new key)

**Required Settings:**
- ✅ Sign In with Apple: Enabled
- ✅ Primary App ID: `com.openslot.app`
- ✅ Return URL: `https://open-mic-5cc8e.firebaseapp.com/__/auth/handler`

### 2. Firebase Console Configuration
**Service ID:** `com.openslot.app.service`
**Apple Team ID:** `4GCYNC6WXK`
**Key ID:** `K84396S22D`
**Private Key:** Contents of `AuthKey_K84396S22D.p8`

### 3. Flutter App Configuration
**Client ID:** `com.openslot.app.service`
**Redirect URI:** `https://open-mic-5cc8e.firebaseapp.com/__/auth/handler`

## Potential Issues

### Issue 1: Service ID Mismatch
- Check if Service ID is exactly `com.openslot.app.service` everywhere
- Make sure it's not `com.openslot.app` (missing .service)

### Issue 2: Key ID Mismatch
- Verify Key ID `K84396S22D` is used in both Apple Developer Console and Firebase
- Make sure the private key content matches the new key file

### Issue 3: Bundle ID Mismatch
- Verify your app's bundle ID is `com.openslot.app`
- Check that this matches the Primary App ID in Apple Developer Console

### Issue 4: Callback URL Mismatch
- Verify the callback URL is exactly: `https://open-mic-5cc8e.firebaseapp.com/__/auth/handler`
- No extra spaces or characters

## Next Steps

1. **Double-check Apple Developer Console:**
   - Service ID configuration
   - Key configuration
   - Return URL configuration

2. **Double-check Firebase Console:**
   - Service ID
   - Team ID
   - Key ID
   - Private Key content

3. **Test with a different Apple ID:**
   - Try signing in with a different Apple ID
   - Some Apple IDs might have restrictions

4. **Check Apple Developer Account:**
   - Ensure your Apple Developer account is active
   - Verify the team has proper permissions 