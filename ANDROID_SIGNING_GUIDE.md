# 🔐 Android Release Signing Setup Guide

## Quick Setup (5 minutes)

### Step 1: Create Release Keystore
```bash
cd /Users/senaimotley/openslot
./setup_android_signing.sh
```

**You'll be asked for:**
1. **Keystore password** - Create a strong password (write it down!)
2. **Key password** - Can be same as keystore password
3. **Your name** - e.g., "Senai Motley"
4. **Organization** - e.g., "OpenSlot"
5. **City, State, Country** - e.g., "San Francisco, CA, US"

### Step 2: Update Build Configuration
```bash
./update_android_build_config.sh
```

### Step 3: Test Release Build
```bash
flutter build appbundle --release
```

---

## 🔒 Security & Backup

### CRITICAL: Backup Your Keystore! ⚠️

Your keystore is stored at: `~/.android/openslot-release.keystore`

**You MUST backup this file!** Without it, you cannot update your app on Google Play.

**Backup locations to consider:**
- [ ] Password manager (attach file)
- [ ] Secure cloud storage (Google Drive, iCloud, encrypted)
- [ ] External hard drive
- [ ] USB drive in safe place

**Also save:**
- [ ] Keystore password
- [ ] Key password
- [ ] Key alias (openslot)

---

## 📋 What Gets Created

| File | Location | Purpose | In Git? |
|------|----------|---------|---------|
| `openslot-release.keystore` | `~/.android/` | Signs your releases | ❌ No |
| `key.properties` | `android/` | Stores passwords | ❌ No |
| `build.gradle` (updated) | `android/app/` | Uses keystore | ✅ Yes |
| `proguard-rules.pro` | `android/app/` | Code optimization | ✅ Yes |

---

## 🧪 Testing

### Build Release AAB
```bash
flutter build appbundle --release
```

**Output location:**
```
build/app/outputs/bundle/release/app-release.aab
```

### Build Release APK (for testing)
```bash
flutter build apk --release
```

**Output location:**
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🚀 Publishing to Google Play

1. **Build release AAB:**
   ```bash
   flutter build appbundle --release
   ```

2. **Go to Google Play Console:**
   https://play.google.com/console

3. **Upload AAB:**
   - Navigate to your app
   - Production → Create new release
   - Upload `app-release.aab`
   - Fill in release notes
   - Submit for review

---

## ⚠️ Common Issues

### Issue: "Keystore file not found"
**Solution:** Make sure keystore path in `key.properties` is correct:
```bash
cat android/key.properties
```

### Issue: "Wrong password"
**Solution:** Verify passwords in `key.properties` match what you set during keystore creation

### Issue: "Key not found"
**Solution:** Check that keyAlias is "openslot" in `key.properties`

---

## 🔄 Keystore Information

To view your keystore details:
```bash
keytool -list -v -keystore ~/.android/openslot-release.keystore
```

To get SHA-1 (needed for some services):
```bash
keytool -list -v -keystore ~/.android/openslot-release.keystore -alias openslot
```

---

## 📊 Signing Status Checklist

- [ ] Keystore created
- [ ] Passwords saved securely
- [ ] key.properties created
- [ ] build.gradle updated
- [ ] Keystore backed up (IMPORTANT!)
- [ ] Test build successful
- [ ] Ready for Play Store upload

---

## 🆘 Lost Your Keystore?

If you lose your keystore or passwords:
- ❌ You CANNOT update your existing app
- ❌ You must create a NEW app listing with a different package name
- ⚠️ All existing users cannot receive updates

**This is why backup is CRITICAL!**

---

## ✅ Next Steps After Setup

1. ✅ Android signing configured
2. ⏭️ Deploy Firebase Hosting (privacy policy, etc.)
3. ⏭️ Test payment flow end-to-end
4. ⏭️ Prepare Play Store listing
5. ⏭️ Submit for review

---

**Good luck with your launch!** 🚀

