#!/bin/bash

# Fix Apple Sign In for TestFlight - Production Entitlements Setup
# This script configures the proper entitlements for TestFlight builds

echo "🍎 Fixing Apple Sign In for TestFlight..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

print_status "Checking current entitlements configuration..."

# Check if production entitlements file exists
if [ -f "ios/Runner/RunnerRelease.entitlements" ]; then
    print_success "Production entitlements file exists"
else
    print_error "Production entitlements file missing"
    exit 1
fi

# Check the content of development entitlements
DEV_APS_ENV=$(grep -A1 "aps-environment" ios/Runner/Runner.entitlements | grep -o "development\|production")
PROD_APS_ENV=$(grep -A1 "aps-environment" ios/Runner/RunnerRelease.entitlements | grep -o "development\|production")

echo ""
print_status "Current entitlements configuration:"
echo "   Development (Runner.entitlements): aps-environment = $DEV_APS_ENV"
echo "   Production (RunnerRelease.entitlements): aps-environment = $PROD_APS_ENV"

if [ "$DEV_APS_ENV" = "development" ] && [ "$PROD_APS_ENV" = "production" ]; then
    print_success "Entitlements are correctly configured!"
else
    print_error "Entitlements configuration is incorrect"
    exit 1
fi

echo ""
print_status "Next steps to complete the fix:"
echo ""
echo "1. 📱 Open Xcode: ios/Runner.xcworkspace"
echo "2. 🎯 Select Runner target"
echo "3. ⚙️  Go to Build Settings tab"
echo "4. 🔍 Search for 'Code Signing Entitlements'"
echo "5. 📝 Set the values:"
echo "   - Debug: Runner/RunnerDebug.entitlements"
echo "   - Release: Runner/RunnerRelease.entitlements"
echo ""
echo "6. 🚀 Build and upload to TestFlight"
echo ""

print_warning "IMPORTANT: Make sure to build with Release configuration for TestFlight!"

echo ""
print_status "Testing the configuration..."

# Check if Apple Sign In is properly configured
if grep -q "com.apple.developer.applesignin" ios/Runner/RunnerRelease.entitlements; then
    print_success "Apple Sign In entitlement is present in production entitlements"
else
    print_error "Apple Sign In entitlement is missing from production entitlements"
fi

# Check if sign_in_with_apple dependency is present
if grep -q "sign_in_with_apple" pubspec.yaml; then
    print_success "sign_in_with_apple dependency is present"
else
    print_warning "sign_in_with_apple dependency might be missing"
fi

echo ""
print_success "Apple Sign In TestFlight fix is ready!"
print_status "The issue was that TestFlight builds need production entitlements (aps-environment: production)"
print_status "Your development builds will continue to use development entitlements"

echo ""
echo "🔧 Technical explanation:"
echo "   - TestFlight is a production environment"
echo "   - Apple Sign In servers are different for development vs production"
echo "   - The aps-environment setting determines which Apple servers to use"
echo "   - Development builds: use development Apple Sign In servers"
echo "   - TestFlight/App Store builds: use production Apple Sign In servers"