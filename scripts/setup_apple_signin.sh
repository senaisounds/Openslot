#!/bin/bash

# Apple Sign In Setup Script for OpenSlot
# This script helps set up the infrastructure for Apple Sign In

echo "🍎 Apple Sign In Infrastructure Setup for OpenSlot"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

print_status "Starting Apple Sign In setup..."

# 1. Check current configuration
print_status "Checking current configuration..."

# Check if Apple Sign In is in pubspec.yaml
if grep -q "sign_in_with_apple" pubspec.yaml; then
    print_success "sign_in_with_apple package is already in pubspec.yaml"
else
    print_warning "sign_in_with_apple package not found in pubspec.yaml"
fi

# Check iOS entitlements
if [ -f "ios/Runner/Runner.entitlements" ]; then
    if grep -q "com.apple.developer.applesignin" ios/Runner/Runner.entitlements; then
        print_success "Apple Sign In entitlement is configured"
    else
        print_warning "Apple Sign In entitlement not found"
    fi
else
    print_error "iOS entitlements file not found"
fi

# Check Info.plist
if [ -f "ios/Runner/Info.plist" ]; then
    if grep -q "signinwithapple" ios/Runner/Info.plist; then
        print_success "Apple Sign In URL scheme is configured"
    else
        print_warning "Apple Sign In URL scheme not found"
    fi
else
    print_error "iOS Info.plist file not found"
fi

# 2. Check Firebase configuration
print_status "Checking Firebase configuration..."

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    print_success "Firebase configuration file exists"
    BUNDLE_ID=$(grep -A 1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist | tail -1 | sed 's/<[^>]*>//g' | tr -d '\t')
    print_status "Bundle ID: $BUNDLE_ID"
else
    print_error "Firebase configuration file not found"
fi

# 3. Check Xcode project
print_status "Checking Xcode project..."

if [ -d "ios/Runner.xcodeproj" ]; then
    print_success "Xcode project exists"
else
    print_error "Xcode project not found"
fi

# 4. Manual setup instructions
echo ""
echo "📋 Manual Setup Required:"
echo "========================"
echo ""
echo "1. 🔥 Firebase Console Setup:"
echo "   - Go to https://console.firebase.google.com"
echo "   - Select project: open-mic-5cc8e"
echo "   - Navigate to Authentication → Sign-in method"
echo "   - Enable Apple provider"
echo "   - Configure with your Apple Developer credentials"
echo ""
echo "2. 🍎 Apple Developer Console:"
echo "   - Go to https://developer.apple.com"
echo "   - Navigate to Certificates, Identifiers & Profiles"
echo "   - Create/configure App ID with Sign in with Apple capability"
echo "   - Create Service ID: com.openslot.app"
echo "   - Generate private key for Sign in with Apple"
echo ""
echo "3. 🔧 Xcode Configuration:"
echo "   - Open ios/Runner.xcworkspace"
echo "   - Select Runner target"
echo "   - Go to Signing & Capabilities"
echo "   - Add 'Sign in with Apple' capability"
echo ""
echo "4. 📱 Testing:"
echo "   - Test on physical device (required for Apple Sign In)"
echo "   - Ensure device is trusted in Xcode"
echo "   - Test with fresh Apple ID"
echo ""

# 5. Check for common issues
print_status "Checking for common issues..."

# Check if running on simulator
if [[ "$OSTYPE" == "darwin"* ]]; then
    if xcrun simctl list devices | grep -q "Booted"; then
        print_warning "Running on iOS Simulator - Apple Sign In may not work properly"
        print_warning "Test on physical device for full functionality"
    fi
fi

# Check Flutter doctor
print_status "Running Flutter doctor..."
flutter doctor --android-licenses > /dev/null 2>&1

# 6. Hot reload test
print_status "Testing hot reload..."
if pgrep -f "flutter run" > /dev/null; then
    print_success "Flutter is running with hot reload"
    echo "Press 'r' in the terminal for hot reload"
    echo "Press 'R' for hot restart"
else
    print_warning "Flutter is not running"
    echo "Run 'flutter run --hot' to start development"
fi

echo ""
print_success "Setup check completed!"
echo ""
echo "📚 Next Steps:"
echo "1. Follow the manual setup instructions above"
echo "2. Configure Firebase console with Apple credentials"
echo "3. Set up Apple Developer console"
echo "4. Test on physical device"
echo "5. Remove debug mode block (already done)"
echo ""
echo "🔗 Useful Links:"
echo "- Firebase Console: https://console.firebase.google.com"
echo "- Apple Developer: https://developer.apple.com"
echo "- Apple Sign In Docs: https://developer.apple.com/sign-in-with-apple/"
echo "- Firebase Auth Docs: https://firebase.google.com/docs/auth/ios/apple"
echo ""
print_success "Apple Sign In infrastructure setup guide completed!" 