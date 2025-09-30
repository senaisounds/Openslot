#!/bin/bash

# iOS Build Fix Script for OpenSlot
# This script resolves common iOS build issues, especially for Xcode Cloud

set -e

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
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header "🍎 iOS Build Fix Script"
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the Flutter project root directory"
    exit 1
fi

print_header "🧹 Cleaning existing build artifacts..."

# Clean Flutter
print_warning "Cleaning Flutter build cache..."
flutter clean

# Remove iOS build artifacts
if [ -d "ios/Pods" ]; then
    print_warning "Removing existing Pods directory..."
    rm -rf ios/Pods
fi

if [ -f "ios/Podfile.lock" ]; then
    print_warning "Removing existing Podfile.lock..."
    rm -f ios/Podfile.lock
fi

# Remove derived data
if [ -d "ios/build" ]; then
    print_warning "Removing iOS build directory..."
    rm -rf ios/build
fi

print_success "Cleanup completed"

print_header "📦 Regenerating dependencies..."

# Set proper encoding for CocoaPods
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Get Flutter dependencies
print_warning "Running flutter pub get..."
flutter pub get

# Install CocoaPods
print_warning "Installing CocoaPods dependencies..."
cd ios
pod install --repo-update
cd ..

print_success "Dependencies regenerated"

print_header "🔍 Verifying build files..."

# Check critical files exist
CRITICAL_FILES=(
    "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Release-input-files.xcfilelist"
    "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-resources-Release-input-files.xcfilelist"
    "ios/Podfile.lock"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "Found: $file"
    else
        print_error "Missing: $file"
        exit 1
    fi
done

print_header "🏗️  Testing iOS build..."

# Test build without code signing
print_warning "Running test build (no code signing)..."
flutter build ios --no-codesign

print_success "iOS build test completed successfully!"

print_header "📋 Summary"
echo ""
echo "✅ Flutter cache cleaned"
echo "✅ iOS Pods regenerated"
echo "✅ Critical build files verified"
echo "✅ Test build completed"
echo ""
print_success "iOS build issues have been resolved!"
print_warning "You can now commit the changes and push to trigger Xcode Cloud rebuild"

echo ""
echo "To commit the changes:"
echo "  git add ios/Podfile.lock"
echo "  git commit -m 'Fix iOS build dependencies'"
echo "  git push"
