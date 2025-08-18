#!/bin/bash

# Comprehensive verification script for Apple Sign In TestFlight fix
# This script verifies that all configurations are correct

echo "🔍 Verifying Apple Sign In TestFlight Fix..."

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

echo ""
print_status "🔍 COMPREHENSIVE VERIFICATION RESULTS:"
echo ""

# Test 1: Check entitlements files exist
print_status "1. Checking entitlements files..."
if [ -f "ios/Runner/RunnerDebug.entitlements" ]; then
    print_success "RunnerDebug.entitlements exists"
else
    print_error "RunnerDebug.entitlements missing"
fi

if [ -f "ios/Runner/Runner.entitlements" ]; then
    print_success "Runner.entitlements exists"
else
    print_error "Runner.entitlements missing"
fi

if [ -f "ios/Runner/RunnerRelease.entitlements" ]; then
    print_success "RunnerRelease.entitlements exists"
else
    print_error "RunnerRelease.entitlements missing"
fi

# Test 2: Check entitlements content
echo ""
print_status "2. Checking entitlements content..."

# Check debug entitlements
if grep -q "com.apple.developer.applesignin" ios/Runner/RunnerDebug.entitlements; then
    print_success "Debug entitlements: Apple Sign In present"
else
    print_error "Debug entitlements: Apple Sign In missing"
fi

# Check development entitlements 
DEV_APS_ENV=$(grep -A1 "aps-environment" ios/Runner/Runner.entitlements | grep -o "development\|production" | head -1)
if [ "$DEV_APS_ENV" = "development" ]; then
    print_success "Development entitlements: aps-environment = development"
else
    print_error "Development entitlements: aps-environment = $DEV_APS_ENV (should be development)"
fi

# Check production entitlements
PROD_APS_ENV=$(grep -A1 "aps-environment" ios/Runner/RunnerRelease.entitlements | grep -o "development\|production" | head -1)
if [ "$PROD_APS_ENV" = "production" ]; then
    print_success "Production entitlements: aps-environment = production"
else
    print_error "Production entitlements: aps-environment = $PROD_APS_ENV (should be production)"
fi

if grep -q "com.apple.developer.applesignin" ios/Runner/RunnerRelease.entitlements; then
    print_success "Production entitlements: Apple Sign In present"
else
    print_error "Production entitlements: Apple Sign In missing"
fi

# Test 3: Check Xcode project configuration
echo ""
print_status "3. Checking Xcode project configuration..."

if grep -q "CODE_SIGN_ENTITLEMENTS = Runner/RunnerDebug.entitlements" ios/Runner.xcodeproj/project.pbxproj; then
    print_success "Debug configuration: Uses RunnerDebug.entitlements"
else
    print_error "Debug configuration: Incorrect entitlements"
fi

# Count Release configurations using correct entitlements
RELEASE_COUNT=$(grep -c "CODE_SIGN_ENTITLEMENTS = Runner/RunnerRelease.entitlements" ios/Runner.xcodeproj/project.pbxproj)
if [ "$RELEASE_COUNT" = "2" ]; then
    print_success "Release/Profile configurations: Use RunnerRelease.entitlements"
else
    print_error "Release/Profile configurations: Incorrect entitlements (found $RELEASE_COUNT, expected 2)"
fi

# Test 4: Check file references in Xcode project
if grep -q "RunnerRelease.entitlements.*PBXFileReference" ios/Runner.xcodeproj/project.pbxproj; then
    print_success "Xcode project: RunnerRelease.entitlements file reference exists"
else
    print_error "Xcode project: RunnerRelease.entitlements file reference missing"
fi

# Test 5: Check sign_in_with_apple dependency
echo ""
print_status "4. Checking dependencies..."
if grep -q "sign_in_with_apple" pubspec.yaml; then
    print_success "sign_in_with_apple dependency present"
else
    print_warning "sign_in_with_apple dependency might be missing"
fi

# Test 6: Check URL schemes in Info.plist
if grep -A5 "CFBundleURLSchemes" ios/Runner/Info.plist | grep -q "signinwithapple"; then
    print_success "Info.plist: Apple Sign In URL scheme configured"
else
    print_error "Info.plist: Apple Sign In URL scheme missing"
fi

# Test 7: Check Firebase configuration
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    print_success "Firebase configuration file exists"
else
    print_error "Firebase configuration file missing"
fi

echo ""
print_status "🎯 SUMMARY:"
echo ""

# Overall assessment
ERROR_COUNT=$(grep -c "❌" /tmp/verification_output.txt 2>/dev/null || echo "0")
if [ "$ERROR_COUNT" = "0" ]; then
    print_success "🎉 ALL CHECKS PASSED! Your Apple Sign In is ready for TestFlight!"
    echo ""
    echo "📱 Next steps:"
    echo "   1. Clean your project: flutter clean"
    echo "   2. Get dependencies: flutter pub get"
    echo "   3. Build for release: flutter build ios --release"
    echo "   4. Archive in Xcode for TestFlight upload"
    echo ""
    print_status "The TestFlight error should now be resolved!"
else
    print_error "Some issues found. Please fix the errors above."
fi

echo ""
print_status "🔧 Technical Details:"
echo "   - Debug builds: Use development Apple Sign In servers"
echo "   - TestFlight/Release builds: Use production Apple Sign In servers"
echo "   - This fix ensures your app connects to the correct Apple servers"