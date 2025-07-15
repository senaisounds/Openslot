#!/bin/bash

# OpenSlot Production Build Script
# This script builds the app for production and App Store submission

set -e

echo "🚀 Starting OpenSlot production build..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build for iOS
echo "📱 Building for iOS..."
flutter build ios --release --no-codesign

# Build for Android
echo "🤖 Building for Android..."
flutter build appbundle --release

# Build for Web
echo "🌐 Building for Web..."
flutter build web --release

echo "✅ Production builds completed successfully!"
echo ""
echo "📦 Build artifacts:"
echo "   • iOS: build/ios/archive/Runner.xcarchive"
echo "   • Android: build/app/outputs/bundle/release/app-release.aab"
echo "   • Web: build/web/"
echo ""
echo "🚀 Next steps:"
echo "   1. Open Xcode and archive the iOS app"
echo "   2. Upload to App Store Connect"
echo "   3. Submit for review"
