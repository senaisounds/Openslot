#!/bin/bash

# This script directly updates the app icon files with a new orange "OS" microphone logo
# It creates a simple orange "OS" logo similar to what's shown in the image

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick is required but not installed. Please install it."
    echo "macOS: brew install imagemagick"
    exit 1
fi

# Create a new microphone OS logo
create_logo() {
    local size=$1
    local output_file=$2
    
    # Create a blank canvas with gradient background
    magick -size ${size}x${size} \
        gradient:"#FF6F00-#9C27B0" \
        -bordercolor black -border 1 \
        -fill white \
        "$output_file"
    
    # Add the text "OS" with a microphone in between
    magick "$output_file" \
        -gravity center \
        -pointsize $(echo "$size * 0.4" | bc | cut -d. -f1) \
        -font Arial-Bold \
        -fill "#FF6F00" \
        -draw "text 0,0 'OS'" \
        "$output_file"
    
    # Add a simple microphone symbol in the middle
    local mic_size=$(echo "$size * 0.2" | bc | cut -d. -f1)
    magick "$output_file" \
        -gravity center \
        -stroke "#000000" -strokewidth 2 \
        -fill "none" \
        -draw "circle $(echo "$size/2" | bc),$(echo "$size/2" | bc) $(echo "$size/2 + $mic_size" | bc),$(echo "$size/2" | bc)" \
        "$output_file"
}

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
    create_logo $size "ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename"
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
    create_logo $size "android/app/src/main/res/$dir/ic_launcher.png"
done

echo "App icons updated successfully!"
echo "You need to rebuild your app to see the changes."
echo "For iOS: cd ios && pod install && cd .."
echo "For Flutter: flutter clean && flutter pub get && flutter run" 