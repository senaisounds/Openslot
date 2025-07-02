#!/bin/bash

# Force HTML renderer for Flutter web
export FLUTTER_WEB_RENDERER=html

echo "Starting Flutter web app with HTML renderer..."

# Clean build if needed
if [ "$1" == "--clean" ]; then
  echo "Cleaning previous build..."
  flutter clean
  rm -rf build/web
fi

# Run the web app with HTML renderer
flutter run -d chrome

echo "Flutter web app terminated." 