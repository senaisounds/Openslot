#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "   ${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "   ${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "   ${RED}❌ $1${NC}"
}

print_header "🍎 Apple Developer Configuration Checker"
echo ""

# Extract bundle ID and team ID
BUNDLE_ID="com.openslot.app"
TEAM_ID="4GCYNC6WXK"

print_header "📱 App Configuration"
echo "   Bundle ID: $BUNDLE_ID"
echo "   Team ID: $TEAM_ID"
echo ""

print_header "🔍 Required Apple Developer Console Configuration"
echo ""

echo -e "${YELLOW}Please verify the following in Apple Developer Console:${NC}"
echo ""

echo "1. 📋 App ID Configuration:"
echo "   • Go to: https://developer.apple.com/account/resources/identifiers/list"
echo "   • Find App ID: $BUNDLE_ID"
echo "   • Verify 'Sign In with Apple' capability is enabled"
echo ""

echo "2. 🔑 Services ID Configuration:"
echo "   • Go to: https://developer.apple.com/account/resources/identifiers/list/serviceId"
echo "   • Create or find Services ID: $BUNDLE_ID"
echo "   • Configure 'Sign In with Apple' for this Services ID"
echo "   • Add Return URLs:"
echo "     - https://open-mic-5cc8e.firebaseapp.com/__/auth/handler"
echo "     - https://open-mic-5cc8e.firebaseapp.com/"
echo ""

echo "3. 🔐 Key Configuration:"
echo "   • Go to: https://developer.apple.com/account/resources/authkeys/list"
echo "   • Create or find an Apple Sign In key"
echo "   • Enable 'Sign In with Apple' for this key"
echo "   • Associate with your App ID: $BUNDLE_ID"
echo ""

print_header "🔧 Firebase Console Configuration"
echo ""
echo "4. 🔥 Firebase Authentication Setup:"
echo "   • Go to: https://console.firebase.google.com/project/open-mic-5cc8e/authentication/providers"
echo "   • Enable Apple Sign-In provider"
echo "   • Configure with:"
echo "     - OAuth redirect URI: https://open-mic-5cc8e.firebaseapp.com/__/auth/handler"
echo "     - Apple Team ID: $TEAM_ID"
echo "     - Services ID: $BUNDLE_ID"
echo "     - Apple Sign In Key ID and Private Key (from step 3)"
echo ""

print_header "🧪 Testing Instructions"
echo ""
echo "After completing the above configuration:"
echo "1. Wait 10-15 minutes for changes to propagate"
echo "2. Build and run the app on a physical iOS device"
echo "3. Test Apple Sign In - you should see:"
echo "   • Full Apple Sign In dialog with privacy options"
echo "   • 'Hide My Email' option"
echo "   • Proper name/email scope selection"
echo ""

print_header "⚠️  Common Issues"
echo ""
print_warning "If Apple Sign In still shows 'Invalid configuration':"
echo "   • Verify the Services ID exactly matches: $BUNDLE_ID"
echo "   • Ensure Return URLs are exactly as shown above"
echo "   • Check that the Apple Sign In key is active and properly configured"
echo "   • Verify the Team ID matches: $TEAM_ID"
echo ""

print_warning "If 'Hide My Email' doesn't appear:"
echo "   • This requires proper Services ID configuration"
echo "   • The Return URLs must be correctly set"
echo "   • The Apple Sign In capability must be enabled for the App ID"
echo ""

echo -e "${GREEN}🎯 Once properly configured, Apple Sign In will show full privacy options!${NC}"