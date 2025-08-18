#!/bin/bash

# Easy TestFlight Build Script
# This script builds and prepares your app for TestFlight upload

echo "🚀 Building for TestFlight..."

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
print_status "🧹 Step 1: Cleaning project..."
flutter clean
if [ $? -eq 0 ]; then
    print_success "Project cleaned"
else
    print_error "Failed to clean project"
    exit 1
fi

echo ""
print_status "📦 Step 2: Getting dependencies..."
flutter pub get
if [ $? -eq 0 ]; then
    print_success "Dependencies updated"
else
    print_error "Failed to get dependencies"
    exit 1
fi

echo ""
print_status "🔨 Step 3: Building iOS release..."
flutter build ios --release
if [ $? -eq 0 ]; then
    print_success "iOS release build completed"
else
    print_error "Failed to build iOS release"
    exit 1
fi

echo ""
print_success "🎉 Build completed successfully!"
echo ""
print_status "📱 Next steps for TestFlight upload:"
echo ""
echo "1. 📱 Open Xcode: ios/Runner.xcworkspace"
echo "2. 🎯 Select 'Any iOS Device (arm64)' as destination"
echo "3. 📦 Go to Product → Archive"
echo "4. 🚀 When archive completes, click 'Distribute App'"
echo "5. 📤 Choose 'App Store Connect'"
echo "6. ⬆️  Follow the upload wizard"
echo ""
print_warning "IMPORTANT: Make sure to select Release configuration for archiving!"
echo ""
print_status "Your Apple Sign In should now work perfectly on TestFlight! 🎉"
echo ""
echo "🔧 What was fixed:"
echo "   ✅ Production entitlements created for TestFlight builds"
echo "   ✅ aps-environment set to 'production' for Release builds"
echo "   ✅ Xcode project configured to use correct entitlements"
echo "   ✅ Apple Sign In will now connect to production servers"