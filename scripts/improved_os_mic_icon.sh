#!/bin/bash

# This script creates app icons with the OS microphone logo design
# It generates an improved icon closely matching the reference image

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick is required but not installed. Please install it."
    echo "macOS: brew install imagemagick"
    exit 1
fi

# Create directory for temp files
mkdir -p temp_icons

# Create a more accurate logo matching the reference image
echo "Creating improved OS mic logo..."

# Create base background with better gradient
magick -size 1024x1024 \
    gradient:"#FF7400-#9C27B0" \
    temp_icons/improved_bg.png

# Create a better rounded rectangle sign with border
magick -size 1024x1024 xc:none \
    -fill white -stroke black -strokewidth 15 \
    -draw "roundrectangle 180,300 844,724 60,60" \
    temp_icons/improved_sign_border.png

# Create inner sign (white area)
magick -size 1024x1024 xc:none \
    -fill white \
    -draw "roundrectangle 195,315 829,709 45,45" \
    temp_icons/improved_sign_inner.png

# Create better microphone
magick -size 1024x1024 xc:none \
    -fill black \
    -draw "circle 512,512 512,580" \
    -draw "rectangle 477,512 547,650" \
    -draw "roundrectangle 447,630 577,670 15,15" \
    temp_icons/improved_mic.png

# Add mic grid lines
magick -size 1024x1024 xc:none \
    -fill none -stroke black -strokewidth 8 \
    -draw "line 490,460 490,560" \
    -draw "line 512,460 512,560" \
    -draw "line 534,460 534,560" \
    -draw "line 477,480 547,480" \
    -draw "line 477,510 547,510" \
    -draw "line 477,540 547,540" \
    temp_icons/improved_mic_grid.png

# Draw the "O" letter
magick -size 1024x1024 xc:none \
    -fill black \
    -font Arial-Bold -pointsize 250 \
    -gravity west \
    -draw "text 240,0 'O'" \
    temp_icons/improved_o.png

# Draw the "S" letter
magick -size 1024x1024 xc:none \
    -fill black \
    -font Arial-Bold -pointsize 250 \
    -gravity east \
    -draw "text 240,0 'S'" \
    temp_icons/improved_s.png

# Combine all elements carefully
magick temp_icons/improved_bg.png \
    temp_icons/improved_sign_border.png -compose over -composite \
    temp_icons/improved_sign_inner.png -compose over -composite \
    temp_icons/improved_o.png -compose over -composite \
    temp_icons/improved_s.png -compose over -composite \
    temp_icons/improved_mic.png -compose over -composite \
    temp_icons/improved_mic_grid.png -compose over -composite \
    temp_icons/final_os_mic_icon.png

echo "Improved icon created successfully!"

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
    magick temp_icons/final_os_mic_icon.png -resize ${size}x${size} "ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename"
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
    magick temp_icons/final_os_mic_icon.png -resize ${size}x${size} "android/app/src/main/res/$dir/ic_launcher.png"
done

echo "App icons updated successfully!"
echo "You need to rebuild your app to see the changes."
echo "For iOS: cd ios && pod install && cd .."
echo "For Flutter: flutter clean && flutter pub get && flutter run" 