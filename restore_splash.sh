#!/bin/bash

# Script to restore the original splash screen

echo "Restoring the original splash screen..."

# Clean the project
flutter clean
flutter pub get

# Build the app
echo "Building the app with the restored splash screen..."
flutter run

echo "✅ Original splash screen has been restored!"
echo "✅ The app now shows the animated OPEN SLOT splash screen"
echo "✅ Your app icon is still the new Openslot logo that users tap on their devices" 