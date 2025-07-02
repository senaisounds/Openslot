#!/bin/bash

# This script creates app icons with the OS microphone logo design
# It generates a proper icon with O (microphone) S on a gradient background

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick is required but not installed. Please install it."
    echo "macOS: brew install imagemagick"
    exit 1
fi

# Create directory for temp files
mkdir -p temp_icons

# Create a base logo with the "OS" microphone design - more accurate to the image
echo "Creating OS mic logo..."

# Create base background with gradient
magick -size 1024x1024 \
    gradient:"#FF6F00-#9C27B0" \
    -fill white \
    temp_icons/background.png

# Create a rounded rectangle sign
magick -size 1024x1024 \
    xc:none \
    -fill white \
    -draw "roundrectangle 200,300 824,724 50,50" \
    temp_icons/sign.png

# Create the microphone in the middle
magick -size 1024x1024 \
    xc:none \
    -fill black \
    -draw "circle 512,512 512,612" \
    -draw "rectangle 462,512 562,700" \
    -draw "rectangle 412,650 612,700" \
    -draw "rectangle 462,412 562,512" \
    -fill white \
    -draw "rectangle 472,422 552,502" \
    -draw "line 492,422 492,502" \
    -draw "line 512,422 512,502" \
    -draw "line 532,422 532,502" \
    temp_icons/mic.png

# Draw the O letter
magick -size 1024x1024 \
    xc:none \
    -fill black \
    -gravity west \
    -pointsize 240 \
    -font Arial-Bold \
    -draw "text 230,0 'O'" \
    temp_icons/letter_o.png

# Draw the S letter
magick -size 1024x1024 \
    xc:none \
    -fill black \
    -gravity east \
    -pointsize 240 \
    -font Arial-Bold \
    -draw "text 230,0 'S'" \
    temp_icons/letter_s.png

# Combine all elements
magick temp_icons/background.png \
    temp_icons/sign.png -compose over -composite \
    temp_icons/letter_o.png -compose over -composite \
    temp_icons/letter_s.png -compose over -composite \
    temp_icons/mic.png -compose over -composite \
    -bordercolor black -border 1 \
    temp_icons/os_mic_icon.png

echo "Base icon created successfully!"

# Update iOS icons
echo "Updating iOS app icons..."
mkdir -p ios/Runner/Assets.xcassets/AppIcon.appiconset

# Define iOS icon sizes
IOS_SIZES=(
  "20 Icon-App-20x20@1x.png"
  "40 Icon-App-20x20@2x.png"
  "60 Icon-App-20x20@3x.png"
  "29 Icon-App-29x29@1x.png"
  "58 Icon-App-29x29@2x.png"
  "87 Icon-App-29x29@3x.png"
  "40 Icon-App-40x40@1x.png"
  "80 Icon-App-40x40@2x.png"
  "120 Icon-App-40x40@3x.png"
  "50 Icon-App-50x50@1x.png"
  "100 Icon-App-50x50@2x.png"
  "57 Icon-App-57x57@1x.png"
  "114 Icon-App-57x57@2x.png"
  "120 Icon-App-60x60@2x.png"
  "180 Icon-App-60x60@3x.png"
  "72 Icon-App-72x72@1x.png"
  "144 Icon-App-72x72@2x.png"
  "76 Icon-App-76x76@1x.png"
  "152 Icon-App-76x76@2x.png"
  "167 Icon-App-83.5x83.5@2x.png"
  "1024 Icon-App-1024x1024@1x.png"
)

for entry in "${IOS_SIZES[@]}"; do
    size=$(echo $entry | cut -d' ' -f1)
    filename=$(echo $entry | cut -d' ' -f2)
    echo "Creating $filename (${size}x${size})"
    magick temp_icons/os_mic_icon.png -resize ${size}x${size} "ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename"
done

# Update Android icons
echo "Updating Android app icons..."

# Define Android icon sizes
ANDROID_SIZES=(
  "48 mipmap-mdpi"
  "72 mipmap-hdpi"
  "96 mipmap-xhdpi"
  "144 mipmap-xxhdpi"
  "192 mipmap-xxxhdpi"
)

for entry in "${ANDROID_SIZES[@]}"; do
    size=$(echo $entry | cut -d' ' -f1)
    dir=$(echo $entry | cut -d' ' -f2)
    echo "Creating $dir/ic_launcher.png (${size}x${size})"
    mkdir -p "android/app/src/main/res/$dir"
    magick temp_icons/os_mic_icon.png -resize ${size}x${size} "android/app/src/main/res/$dir/ic_launcher.png"
done

echo "App icons updated successfully!"
echo "You need to rebuild your app to see the changes."
echo "For iOS: cd ios && pod install && cd .."
echo "For Flutter: flutter clean && flutter pub get && flutter run" 