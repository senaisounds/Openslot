# Apple Sign In Infrastructure Setup Guide

## 1. Firebase Console Setup

### Step 1: Enable Apple Sign In Provider
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `open-mic-5cc8e`
3. Navigate to **Authentication** → **Sign-in method**
4. Click on **Apple** provider
5. Enable it and configure:
   - **Service ID**: `com.openslot.app` (your bundle ID)
   - **Apple Team ID**: Get this from Apple Developer Console
   - **Private Key ID**: Get this from Apple Developer Console
   - **Private Key**: Download from Apple Developer Console

### Step 2: Get Apple Developer Credentials
1. Go to [Apple Developer Console](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Go to **Keys** section
4. Create a new key with **Sign in with Apple** capability
5. Download the `.p8` file and note the Key ID
6. Note your Team ID (found in the top right of Apple Developer Console)

## 2. Xcode Configuration

### Step 1: Add Apple Sign In Capability
1. Open your project in Xcode: `ios/Runner.xcworkspace`
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Sign in with Apple**

### Step 2: Update Bundle Identifier
Ensure your bundle ID matches Firebase configuration:
- Current: `com.openslot.app`
- Verify this matches in Firebase console

### Step 3: Update Entitlements
The entitlements file is already configured correctly:
```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

## 3. Flutter Code Updates

### Step 1: Remove Debug Mode Block
Update `lib/pages/login_page.dart` line 361:

```dart
Future<void> _signInWithApple() async {
  // Remove this debug block
  // if (kDebugMode) {
  //   _showError('Apple Sign In is not available in debug mode...');
  //   return;
  // }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  HapticFeedback.lightImpact();

  try {
    final userCredential = await _authService.signInWithApple();
    
    if (userCredential.user != null) {
      await _handleSuccessfulLogin(userCredential.user!);
    }
  } catch (e) {
    Logger.e('Apple Sign In error: $e', tag: 'Login_page');
    _showError('Apple Sign In failed. Please try again or use phone number.');
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

### Step 2: Update Firebase Auth Service
The `signInWithApple()` method in `lib/api/firebase_auth_service.dart` is already properly implemented.

## 4. Apple Developer Console Setup

### Step 1: Create App ID
1. Go to **Identifiers** → **App IDs**
2. Create new App ID or edit existing one
3. Enable **Sign in with Apple** capability
4. Configure domains and redirect URLs:
   - **Primary App ID**: `com.openslot.app`
   - **Website URLs**: `https://openslot.app`
   - **Return URLs**: `https://openslot.app/callback`

### Step 2: Create Service ID
1. Go to **Identifiers** → **Services IDs**
2. Create new Service ID: `com.openslot.app`
3. Enable **Sign in with Apple**
4. Configure domains and redirect URLs

## 5. Testing Setup

### Step 1: Physical Device Testing
Apple Sign In requires a physical device for testing:
1. Connect iPhone to Mac
2. Trust the device in Xcode
3. Run app on physical device
4. Test Apple Sign In flow

### Step 2: Simulator Testing (Limited)
For simulator testing, you can temporarily enable Apple Sign In:
1. Remove the debug mode block
2. Test on iOS Simulator (limited functionality)
3. Note: Some features may not work in simulator

## 6. Production Deployment

### Step 1: App Store Connect
1. Upload app to App Store Connect
2. Ensure **Sign in with Apple** is enabled in app capabilities
3. Submit for review

### Step 2: Firebase Production
1. Ensure production Firebase project has Apple Sign In enabled
2. Use production Apple Developer credentials
3. Test on production devices

## 7. Troubleshooting

### Common Issues:
1. **"Apple Sign In is currently unavailable"**
   - Check Firebase console configuration
   - Verify Apple Developer credentials
   - Ensure physical device testing

2. **"Invalid client" error**
   - Verify bundle ID matches in all places
   - Check Apple Developer console configuration
   - Ensure Firebase project settings are correct

3. **"Network error"**
   - Check internet connection
   - Verify Apple servers are accessible
   - Check Firebase project status

### Debug Steps:
1. Enable verbose logging in Firebase Auth
2. Check Xcode console for detailed error messages
3. Verify all configuration files are properly set
4. Test with a fresh Apple ID that hasn't been used before

## 8. Security Considerations

### Best Practices:
1. Always use nonce for Apple Sign In
2. Validate tokens on server side
3. Handle user data privacy properly
4. Implement proper error handling
5. Follow Apple's Human Interface Guidelines

### Privacy Compliance:
1. Only request necessary scopes (email, name)
2. Handle private email relay addresses
3. Provide clear privacy policy
4. Allow users to delete their data

## 9. Final Checklist

- [ ] Firebase console: Apple Sign In enabled
- [ ] Apple Developer: App ID configured
- [ ] Apple Developer: Service ID created
- [ ] Apple Developer: Private key downloaded
- [ ] Xcode: Sign in with Apple capability added
- [ ] Flutter: Debug mode block removed
- [ ] Testing: Physical device verified
- [ ] Production: App Store Connect configured
- [ ] Security: Nonce validation implemented
- [ ] Privacy: User data handling configured 