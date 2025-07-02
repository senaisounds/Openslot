#!/bin/bash

# This script fixes the iOS app icons with the orange "OS" microphone logo
# It creates simpler iOS icons to resolve the issue with the app icon set

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick is required but not installed. Please install it."
    echo "macOS: brew install imagemagick"
    exit 1
fi

# Create a base logo with the "OS" microphone style
echo "Creating base logo with 'OS' microphone design..."
mkdir -p temp_icons

# Create the base icon - simple orange S design like the one shown in the image
magick -size 1024x1024 \
    gradient:"#FF6F00-#FF6F00" \
    -gravity center \
    -pointsize 600 \
    -font Arial-Bold \
    -fill white \
    -draw "text 0,0 'S'" \
    temp_icons/base_icon.png

echo "Creating iOS app icons..."
mkdir -p ios/Runner/Assets.xcassets/AppIcon.appiconset

# iOS icon sizes - just the required ones
REQUIRED_SIZES=(
  "40 Icon-App-20x20@2x.png"   # iPhone Notification 2x
  "60 Icon-App-20x20@3x.png"   # iPhone Notification 3x
  "58 Icon-App-29x29@2x.png"   # iPhone Settings 2x
  "87 Icon-App-29x29@3x.png"   # iPhone Settings 3x
  "80 Icon-App-40x40@2x.png"   # iPhone Spotlight 2x
  "120 Icon-App-40x40@3x.png"  # iPhone Spotlight 3x
  "120 Icon-App-60x60@2x.png"  # iPhone App 2x
  "180 Icon-App-60x60@3x.png"  # iPhone App 3x
  "1024 Icon-App-1024x1024@1x.png" # App Store
)

# Generate the iOS icons
for entry in "${REQUIRED_SIZES[@]}"; do
    size=$(echo $entry | cut -d' ' -f1)
    filename=$(echo $entry | cut -d' ' -f2)
    echo "Creating $filename (${size}x${size})"
    magick temp_icons/base_icon.png -resize ${size}x${size} "ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename"
done

echo "iOS app icons created successfully!"
echo "Now run: flutter clean && flutter pub get && flutter run" 