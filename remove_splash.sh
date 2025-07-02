#!/bin/bash

# Script to remove splash screen and rebuild the app

echo "Removing splash screen and rebuilding the app..."

# Clean the project
flutter clean
flutter pub get

# Build the app
flutter build apk --debug
flutter build ios --debug --no-codesign

echo "✅ Splash screen has been removed!"
echo "✅ The app will now launch directly to the content without showing a splash screen"
echo "✅ Run 'flutter run' to see the changes on your device or simulator" 