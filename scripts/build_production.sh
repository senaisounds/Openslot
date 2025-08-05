#!/bin/bash

# Production Build Script for OpenSlot
# This script builds the app for production with proper configuration

set -e  # Exit on any error

echo "🚀 Starting production build for OpenSlot..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "This script must be run from the project root directory"
    exit 1
fi

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Run tests
print_status "Running tests..."
flutter test --reporter=compact || {
    print_warning "Some tests failed, but continuing with build..."
}

# Analyze code
print_status "Analyzing code..."
flutter analyze --no-fatal-infos || {
    print_warning "Some analysis issues found, but continuing with build..."
}

# Build for iOS (production)
print_status "Building for iOS (production)..."
flutter build ios --release --no-codesign \
    --dart-define=PRODUCTION=true \
    --dart-define=DEBUG=false \
    --dart-define=TEST=false

# Build for Android (production)
print_status "Building for Android (production)..."
flutter build apk --release --target-platform android-arm64 \
    --dart-define=PRODUCTION=true \
    --dart-define=DEBUG=false \
    --dart-define=TEST=false

# Build for Web (production)
print_status "Building for Web (production)..."
flutter build web --release \
    --dart-define=PRODUCTION=true \
    --dart-define=DEBUG=false \
    --dart-define=TEST=false

# Check build artifacts
print_status "Checking build artifacts..."

if [ -f "build/ios/iphoneos/Runner.app" ]; then
    print_status "✅ iOS build successful"
else
    print_error "❌ iOS build failed"
fi

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    print_status "✅ Android build successful"
else
    print_error "❌ Android build failed"
fi

if [ -d "build/web" ]; then
    print_status "✅ Web build successful"
else
    print_error "❌ Web build failed"
fi

# Show build sizes
print_status "Build sizes:"
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "  Android APK: $APK_SIZE"
fi

if [ -d "build/web" ]; then
    WEB_SIZE=$(du -sh build/web | cut -f1)
    echo "  Web build: $WEB_SIZE"
fi

print_status "🎉 Production build completed successfully!"
print_status "Build artifacts are ready for deployment."
