#!/bin/bash

# This script generates app icons for iOS and Android platforms from a source image
# Usage: ./generate_app_icons.sh <source_image>

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is required but not installed. Please install it."
    echo "macOS: brew install imagemagick"
    exit 1
fi

# Check if source image is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <source_image>"
    exit 1
fi

SOURCE_IMAGE=$1

# Create directories if they don't exist
mkdir -p temp_icons/ios
mkdir -p temp_icons/android

echo "Generating iOS app icons..."

# iOS icon sizes
declare -A IOS_SIZES=(
    ["Icon-App-20x20@1x.png"]=20
    ["Icon-App-20x20@2x.png"]=40
    ["Icon-App-20x20@3x.png"]=60
    ["Icon-App-29x29@1x.png"]=29
    ["Icon-App-29x29@2x.png"]=58
    ["Icon-App-29x29@3x.png"]=87
    ["Icon-App-40x40@1x.png"]=40
    ["Icon-App-40x40@2x.png"]=80
    ["Icon-App-40x40@3x.png"]=120
    ["Icon-App-50x50@1x.png"]=50
    ["Icon-App-50x50@2x.png"]=100
    ["Icon-App-57x57@1x.png"]=57
    ["Icon-App-57x57@2x.png"]=114
    ["Icon-App-60x60@2x.png"]=120
    ["Icon-App-60x60@3x.png"]=180
    ["Icon-App-72x72@1x.png"]=72
    ["Icon-App-72x72@2x.png"]=144
    ["Icon-App-76x76@1x.png"]=76
    ["Icon-App-76x76@2x.png"]=152
    ["Icon-App-83.5x83.5@2x.png"]=167
    ["Icon-App-1024x1024@1x.png"]=1024
)

# Generate iOS icons
for icon in "${!IOS_SIZES[@]}"; do
    size=${IOS_SIZES[$icon]}
    echo "Creating $icon (${size}x${size})"
    convert "$SOURCE_IMAGE" -resize ${size}x${size} "temp_icons/ios/$icon"
done

echo "Generating Android app icons..."

# Android icon sizes
declare -A ANDROID_SIZES=(
    ["mipmap-mdpi/ic_launcher.png"]=48
    ["mipmap-hdpi/ic_launcher.png"]=72
    ["mipmap-xhdpi/ic_launcher.png"]=96
    ["mipmap-xxhdpi/ic_launcher.png"]=144
    ["mipmap-xxxhdpi/ic_launcher.png"]=192
)

# Generate Android icons
for icon in "${!ANDROID_SIZES[@]}"; do
    size=${ANDROID_SIZES[$icon]}
    dir=$(dirname "temp_icons/android/$icon")
    mkdir -p "$dir"
    echo "Creating $icon (${size}x${size})"
    convert "$SOURCE_IMAGE" -resize ${size}x${size} "temp_icons/android/$icon"
done

echo "App icons generated in temp_icons directory."
echo "To apply these icons:"
echo "1. For iOS: Copy files from temp_icons/ios/ to ios/Runner/Assets.xcassets/AppIcon.appiconset/"
echo "2. For Android: Copy files from temp_icons/android/ to their respective directories in android/app/src/main/res/" 