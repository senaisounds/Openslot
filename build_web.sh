#!/bin/bash

# Force HTML renderer for Flutter web
export FLUTTER_WEB_RENDERER=html

echo "Building Flutter web app with HTML renderer..."

# Clean previous build if needed
if [ "$1" == "--clean" ]; then
  echo "Cleaning previous build..."
  flutter clean
fi

# Build web app in release mode with HTML renderer
flutter build web --release

echo "Web app built successfully in build/web/"
echo "You can deploy this directory to any web hosting service."
echo ""
echo "To test locally, run: flutter run -d chrome --web-renderer html" 