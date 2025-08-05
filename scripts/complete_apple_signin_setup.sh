#!/bin/bash

# Complete Apple Sign In Setup Script for OpenSlot
# This script will guide you through the entire setup process

echo "🍎 Complete Apple Sign In Setup for OpenSlot"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

print_help() {
    echo -e "${CYAN}[HELP]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

print_status "Starting complete Apple Sign In setup..."

# Step 1: Check current status
print_step "1. Checking current configuration..."

# Check Flutter packages
if grep -q "sign_in_with_apple" pubspec.yaml; then
    print_success "✓ sign_in_with_apple package is installed"
else
    print_error "✗ sign_in_with_apple package not found"
fi

# Check iOS configuration
if [ -f "ios/Runner/Runner.entitlements" ]; then
    if grep -q "com.apple.developer.applesignin" ios/Runner/Runner.entitlements; then
        print_success "✓ Apple Sign In entitlement configured"
    else
        print_warning "⚠ Apple Sign In entitlement not found"
    fi
else
    print_error "✗ iOS entitlements file not found"
fi

if [ -f "ios/Runner/Info.plist" ]; then
    if grep -q "signinwithapple" ios/Runner/Info.plist; then
        print_success "✓ Apple Sign In URL scheme configured"
    else
        print_warning "⚠ Apple Sign In URL scheme not found"
    fi
else
    print_error "✗ iOS Info.plist file not found"
fi

# Check Firebase configuration
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    print_success "✓ Firebase configuration exists"
    BUNDLE_ID=$(grep -A 1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist | tail -1 | sed 's/<[^>]*>//g' | tr -d '\t')
    print_status "Bundle ID: $BUNDLE_ID"
else
    print_error "✗ Firebase configuration not found"
fi

echo ""
print_step "2. Manual Setup Required (I cannot do this for you, but I'll guide you)"
echo "============================================================================="

# Step 2: Apple Developer Console Setup
echo ""
print_step "2A. Apple Developer Console Setup"
echo "--------------------------------------"
echo "1. Go to: https://developer.apple.com"
echo "2. Sign in with your Apple Developer account"
echo "3. Navigate to: Certificates, Identifiers & Profiles"
echo "4. Note your Team ID (top right corner)"
echo ""
echo "5. Create App ID:"
echo "   - Click 'Identifiers' → 'App IDs'"
echo "   - Click '+' to create new App ID"
echo "   - Description: OpenSlot"
echo "   - Bundle ID: com.openslot.app"
echo "   - Enable 'Sign in with Apple' capability"
echo "   - Click 'Continue' and 'Register'"
echo ""
echo "6. Create Service ID:"
echo "   - Click 'Identifiers' → 'Services IDs'"
echo "   - Click '+' to create new Service ID"
echo "   - Description: OpenSlot Apple Sign In"
echo "   - Identifier: com.openslot.app"
echo "   - Enable 'Sign in with Apple'"
echo "   - Configure domains: https://openslot.app"
echo "   - Click 'Continue' and 'Register'"
echo ""
echo "7. Create Private Key:"
echo "   - Click 'Keys' in left sidebar"
echo "   - Click '+' to create new key"
echo "   - Key Name: OpenSlot Apple Sign In"
echo "   - Enable 'Sign in with Apple'"
echo "   - Click 'Continue' and 'Register'"
echo "   - Download the .p8 file"
echo "   - Note the Key ID (shown on confirmation page)"
echo ""

# Step 3: Firebase Console Setup
echo ""
print_step "2B. Firebase Console Setup"
echo "-------------------------------"
echo "1. Go to: https://console.firebase.google.com"
echo "2. Select project: open-mic-5cc8e"
echo "3. Navigate to: Authentication → Sign-in method"
echo "4. Click on 'Apple' provider"
echo "5. Enable it and configure:"
echo "   - Service ID: com.openslot.app"
echo "   - Apple Team ID: [Your Team ID from step 2A]"
echo "   - Private Key ID: [Your Key ID from step 2A]"
echo "   - Private Key: [Paste entire .p8 file content]"
echo "6. Click 'Save'"
echo ""

# Step 4: Xcode Configuration
echo ""
print_step "2C. Xcode Configuration"
echo "----------------------------"
echo "1. Open: ios/Runner.xcworkspace"
echo "2. Select 'Runner' target"
echo "3. Go to 'Signing & Capabilities' tab"
echo "4. Click '+' to add capability"
echo "5. Add 'Sign in with Apple'"
echo "6. Save the project"
echo ""

# Step 5: Testing Instructions
echo ""
print_step "3. Testing Instructions"
echo "---------------------------"
echo "1. Hot reload your app:"
echo "   - Press 'r' in your Flutter terminal"
echo ""
echo "2. Test Apple Sign In:"
echo "   - Try the Apple Sign In button"
echo "   - Note any error messages"
echo ""
echo "3. Common error messages and solutions:"
echo "   - 'Invalid Service ID': Check Apple Developer Console"
echo "   - 'Invalid Team ID': Verify Team ID in Apple Developer Console"
echo "   - 'Invalid Private Key': Check .p8 file format"
echo "   - 'Key not found': Verify Key ID matches"
echo ""

# Step 6: Verification Commands
echo ""
print_step "4. Verification Commands"
echo "----------------------------"
echo "Run these commands to verify setup:"
echo ""
echo "1. Check Flutter packages:"
echo "   flutter pub get"
echo ""
echo "2. Check iOS build:"
echo "   flutter build ios --no-codesign"
echo ""
echo "3. Check current configuration:"
echo "   ./scripts/setup_apple_signin.sh"
echo ""

# Step 7: Troubleshooting
echo ""
print_step "5. Troubleshooting"
echo "---------------------"
echo "If you encounter issues:"
echo ""
echo "1. Check Firebase Console:"
echo "   - Verify Apple provider is enabled"
echo "   - Check all credentials are correct"
echo ""
echo "2. Check Apple Developer Console:"
echo "   - Verify App ID has Sign in with Apple enabled"
echo "   - Verify Service ID is configured"
echo "   - Verify Private Key has correct capabilities"
echo ""
echo "3. Check Xcode:"
echo "   - Verify Sign in with Apple capability is added"
echo "   - Check bundle identifier matches"
echo ""
echo "4. Test on physical device:"
echo "   - Apple Sign In doesn't work well on simulator"
echo "   - Connect iPhone to Mac"
echo "   - Trust device in Xcode"
echo ""

# Step 8: Next Steps
echo ""
print_step "6. Next Steps"
echo "----------------"
echo "After completing the manual setup:"
echo ""
echo "1. Test Apple Sign In on physical device"
echo "2. Verify user data is created in Firebase"
echo "3. Test the complete authentication flow"
echo "4. Prepare for App Store submission"
echo ""

# Step 9: Useful Links
echo ""
print_step "7. Useful Links"
echo "------------------"
echo "Firebase Console: https://console.firebase.google.com"
echo "Apple Developer: https://developer.apple.com"
echo "Apple Sign In Docs: https://developer.apple.com/sign-in-with-apple/"
echo "Firebase Auth Docs: https://firebase.google.com/docs/auth/ios/apple"
echo ""

# Step 10: Current Status Check
echo ""
print_step "8. Current Status Check"
echo "---------------------------"
print_status "Running current status check..."

# Check if Flutter is running
if pgrep -f "flutter run" > /dev/null; then
    print_success "✓ Flutter is running with hot reload"
    echo "   Press 'r' for hot reload"
    echo "   Press 'R' for hot restart"
else
    print_warning "⚠ Flutter is not running"
    echo "   Run 'flutter run --hot' to start development"
fi

# Check for common issues
if [[ "$OSTYPE" == "darwin"* ]]; then
    if xcrun simctl list devices | grep -q "Booted"; then
        print_warning "⚠ Running on iOS Simulator"
        echo "   Apple Sign In may not work properly on simulator"
        echo "   Test on physical device for full functionality"
    fi
fi

echo ""
print_success "Setup guide completed!"
echo ""
print_help "Follow the manual setup steps above, then test your Apple Sign In."
echo ""
print_help "If you encounter any specific errors, let me know and I'll help you troubleshoot!" 