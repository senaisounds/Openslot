#!/bin/bash

# Script to update the Slotted app icon

echo "Updating Slotted app icons and splash screens..."

# Run Flutter launcher icons
flutter pub run flutter_launcher_icons

# Clean the project
flutter clean
flutter pub get

echo "✅ App icons have been successfully updated!"
echo "✅ The app now uses the new Openslot logo for the launcher icon that users tap on their devices"
echo "✅ Splash screens have also been updated with the new logo"
echo "✅ Run 'flutter run' to see the changes on your device or simulator" 