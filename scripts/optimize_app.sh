#!/bin/bash

# optimize_app.sh - Script to optimize the Slotted app for production

echo "Starting app optimization process..."

# Clean build artifacts
echo "Cleaning build artifacts..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Run the Dart analyzer
echo "Running code analysis..."
flutter analyze

# Fix deprecated API usage
echo "Fixing deprecated APIs..."
find . -name "*.dart" -type f -exec sed -i '' -e 's/withOpacity/withValues/g' {} \;

# Analyze performance
echo "Analyzing performance..."
flutter run --profile --trace-startup --cache-sksl --purge-persistent-cache --enable-skparagraph

# Build optimized release version
echo "Building optimized release version..."
flutter build ios --release --obfuscate --split-debug-info=build/symbols

echo "App optimization complete!"
echo "Run 'flutter run --release' to test the optimized version" 