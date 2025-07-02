#!/bin/bash

# This script deploys generated app icons to their respective locations
# Usage: ./deploy_app_icons.sh

# Check if the temp_icons directory exists
if [ ! -d "temp_icons" ]; then
    echo "Error: temp_icons directory not found. Generate icons first using generate_app_icons.sh"
    exit 1
fi

# Deploy iOS icons
echo "Deploying iOS app icons..."
cp -v temp_icons/ios/*.png ios/Runner/Assets.xcassets/AppIcon.appiconset/

# Deploy Android icons
echo "Deploying Android app icons..."
for dir in temp_icons/android/mipmap-*/; do
    base_dir=$(basename "$dir")
    cp -v "$dir"ic_launcher.png android/app/src/main/res/"$base_dir"/ic_launcher.png
done

echo "App icons deployed successfully!"
echo "You may need to clean and rebuild your app to see the changes."
echo "For iOS: cd ios && pod install"
echo "For Flutter: flutter clean && flutter pub get" 