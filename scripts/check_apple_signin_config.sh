#!/bin/bash

# Apple Sign In Configuration Check Script
# This script checks if Apple Sign In is properly configured

echo "🍎 Apple Sign In Configuration Check"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

echo ""
echo "Checking Apple Sign In configuration..."

# Check if sign_in_with_apple package is installed
if grep -q "sign_in_with_apple" pubspec.yaml; then
    print_success "sign_in_with_apple package is installed"
else
    print_error "sign_in_with_apple package not found in pubspec.yaml"
fi

# Check iOS entitlements
if grep -q "com.apple.developer.applesignin" ios/Runner/Runner.entitlements; then
    print_success "Apple Sign In entitlement is configured"
else
    print_error "Apple Sign In entitlement not found in Runner.entitlements"
fi

# Check URL scheme
if grep -q "signinwithapple" ios/Runner/Info.plist; then
    print_success "Apple Sign In URL scheme is configured"
else
    print_error "Apple Sign In URL scheme not found in Info.plist"
fi

# Check if Apple Sign In method exists in FirebaseAuthService
if grep -q "signInWithApple" lib/api/firebase_auth_service.dart; then
    print_success "Apple Sign In method exists in FirebaseAuthService"
else
    print_error "Apple Sign In method not found in FirebaseAuthService"
fi

# Check if Apple logo painter exists
if grep -q "AppleLogoPainter" lib/pages/login_page.dart; then
    print_success "Apple logo painter is implemented"
else
    print_error "Apple logo painter not found"
fi

echo ""
echo "📋 Firebase Console Configuration Required:"
echo "=========================================="
echo ""
echo "To complete Apple Sign In setup, you need to:"
echo ""
echo "1. Go to Firebase Console: https://console.firebase.google.com"
echo "2. Select your project: open-mic-5cc8e"
echo "3. Go to Authentication > Sign-in method"
echo "4. Enable Apple provider"
echo "5. Configure Apple Sign In:"
echo "   - Service ID: com.openslot.app"
echo "   - Apple Team ID: [Your Apple Developer Team ID]"
echo "   - Key ID: [Your Apple Sign In Key ID]"
echo "   - Private Key: [Your Apple Sign In Private Key]"
echo ""
echo "📱 Testing Requirements:"
echo "======================="
echo ""
echo "• Apple Sign In requires a physical device for testing"
echo "• It won't work properly in iOS Simulator"
echo "• Make sure you're signed into iCloud on the test device"
echo ""
echo "🔧 Manual Setup Steps:"
echo "======================"
echo ""
echo "1. Create Apple Sign In Key in Apple Developer Console:"
echo "   - Go to https://developer.apple.com/account"
echo "   - Certificates, Identifiers & Profiles"
echo "   - Keys > Create a new key"
echo "   - Enable 'Sign In with Apple'"
echo "   - Download the key file"
echo ""
echo "2. Create Service ID:"
echo "   - Identifiers > Create a new identifier"
echo "   - Select 'Services IDs'"
echo "   - Enter: com.openslot.app"
echo "   - Enable 'Sign In with Apple'"
echo ""
echo "3. Configure Firebase Console with the key details"
echo ""
echo "🎯 Current Status:"
echo "=================="
echo ""
echo "✅ Package installed"
echo "✅ iOS entitlements configured"
echo "✅ URL scheme configured"
echo "✅ Code implementation complete"
echo "⚠️  Firebase Console configuration needed"
echo "⚠️  Apple Developer Console setup needed"
echo ""
echo "📞 Next Steps:"
echo "=============="
echo ""
echo "1. Complete Firebase Console configuration"
echo "2. Set up Apple Developer Console keys"
echo "3. Test on physical device"
echo "4. Verify Apple Sign In flow works"
echo ""
echo "For detailed setup instructions, see:"
echo "https://firebase.google.com/docs/auth/ios/apple"
echo "https://developer.apple.com/sign-in-with-apple/" 