# Firebase Console Apple Sign In Configuration Guide

## 🎯 **Step-by-Step Instructions**

### **Step 1: Access Firebase Console**
1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Sign in with your Google account
3. Select your project: **open-mic-5cc8e**

### **Step 2: Navigate to Authentication**
1. In the left sidebar, click **Authentication**
2. Click on the **Sign-in method** tab
3. You'll see a list of sign-in providers

### **Step 3: Find Apple Provider**
1. Look for **Apple** in the list of providers
2. Click on **Apple** to open the configuration panel
3. If it's disabled, click the toggle to **Enable** it

### **Step 4: Configure Apple Provider**
Fill in these exact values:

**Service ID:**
```
com.openslot.app.service
```

**Apple Team ID:**
```
4GCYNC6WXK
```

**Private Key ID:**
```
Y4324X3D8U
```

**Private Key:**
- Click **Choose file** or **Upload**
- Select the file: `AuthKey_Y4324X3D8U.p8`
- This is the file you downloaded from Apple Developer Console

### **Step 5: Save Configuration**
1. Click **Save** at the bottom of the configuration panel
2. You should see a success message

### **Step 6: Test the Configuration**
1. Go back to your Flutter app
2. Try the Apple Sign In button
3. It should now work without the error dialog

## 🔧 **Troubleshooting**

### **If you get an error:**
1. **Check the Service ID** - Make sure it's exactly `com.openslot.app.service`
2. **Check the Team ID** - Make sure it's exactly `4GCYNC6WXK`
3. **Check the Key ID** - Make sure it's exactly `Y4324X3D8U`
4. **Check the Private Key** - Make sure you uploaded the correct `.p8` file

### **If Apple Sign In still doesn't work:**
1. **Restart your Flutter app** - Stop and restart `flutter run`
2. **Check Firebase logs** - Look for any error messages
3. **Verify Apple Developer setup** - Make sure the Service ID is properly configured

## 📋 **Summary of Values Used:**

- **Service ID**: `com.openslot.app.service`
- **Team ID**: `4GCYNC6WXK`
- **Key ID**: `Y4324X3D8U`
- **Private Key**: `AuthKey_Y4324X3D8U.p8`

## ✅ **Expected Result:**

After configuring Firebase, your Apple Sign In should work without showing the "currently unavailable" error dialog. 