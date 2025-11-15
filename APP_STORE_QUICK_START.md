# 🍎 App Store - Quick Start Guide

## ✅ **Your iOS Build is Complete!**

**Status:** ✅ Success!  
**Location:** `/Users/senaimotley/openslot/build/ios/iphoneos/Runner.app`  
**Size:** 117.3 MB  
**Version:** 1.0.97 (Build 133)

---

## 🚀 **Quick Steps to Submit (30 minutes)**

### **Step 1: Open Xcode** (1 minute)
```bash
cd /Users/senaimotley/openslot
open ios/Runner.xcworkspace
```

### **Step 2: Set Up Signing** (2 minutes)
1. Click **Runner** (blue icon, left sidebar)
2. Select **Runner** target
3. **"Signing & Capabilities"** tab
4. Enable **"Automatically manage signing"**
5. Select your **Apple Developer team**

**Don't have Apple Developer account?**
→ Sign up at https://developer.apple.com/programs/enroll/ ($99/year)

### **Step 3: Select Device** (30 seconds)
Top of Xcode: Select **"Any iOS Device (arm64)"**

### **Step 4: Archive** (5-10 minutes)
Menu: **Product → Archive**

### **Step 5: Upload** (5-10 minutes)
1. When Organizer opens, select your archive
2. Click **"Distribute App"**
3. Select **"App Store Connect"**
4. Click **"Upload"**
5. Wait for upload to complete

### **Step 6: App Store Connect** (10-15 minutes)
Go to: https://appstoreconnect.apple.com

1. **Create app:** Name = OpenSlot, Bundle ID = com.openslot.app
2. **Fill information:**
   - Description (copy from guide)
   - Screenshots (3-10 images)
   - Privacy policy: https://senaisounds.github.io/Openslot/privacy.html
   - Category: Lifestyle or Entertainment
3. **Select build:** Choose 1.0.97 (Build 133)
4. **Submit for review!**

---

## 📸 **Screenshots Needed (Minimum 3)**

**Size:** 1290 x 2796 pixels (iPhone 6.7")

**What to capture:**
1. Home screen (event list)
2. Event details page
3. Map view

**How to capture:**
```bash
cd /Users/senaimotley/openslot
open -a Simulator
flutter run
# Then: File → New Screenshot in Simulator
```

---

## ⏱️ **Timeline**

| Step | Time |
|------|------|
| Set up Xcode | 3 min |
| Archive | 10 min |
| Upload | 10 min |
| App Store Connect | 15 min |
| **Total to submission** | **~30 min** |
| **Apple review** | **2-7 days** |

---

## 📋 **What You Need**

- ✅ iOS build complete ✓
- ✅ Apple Developer account ($99/year)
- ✅ 3-10 screenshots
- ✅ Privacy policy URL: https://senaisounds.github.io/Openslot/privacy.html
- ✅ Support URL: https://senaisounds.github.io/Openslot/support.html
- ✅ App description (provided in full guide)

---

## 💡 **Quick Tips**

1. **First time?** Start with test account in App Store Connect settings
2. **No screenshots?** Run in Simulator and use Cmd+S
3. **Rejected?** Most common: missing demo account or privacy issues
4. **Questions?** Read `APP_STORE_SUBMISSION_GUIDE.md` for details

---

## 📞 **Links**

- **Full Guide:** `APP_STORE_SUBMISSION_GUIDE.md` (detailed instructions)
- **App Store Connect:** https://appstoreconnect.apple.com
- **Privacy Policy:** https://senaisounds.github.io/Openslot/privacy.html
- **Support:** https://senaisounds.github.io/Openslot/support.html

---

## ✨ **You're Ready!**

Your app is built and waiting. Just follow the 6 steps above and you'll be live in a week! 🚀

**Next command:**
```bash
open ios/Runner.xcworkspace
```

**Then: Product → Archive → Upload!**

Good luck! 🎉

