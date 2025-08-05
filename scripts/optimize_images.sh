#!/bin/bash

# Image Optimization Script for OpenSlot
# This script optimizes images for better app performance

set -e

echo "🖼️  Starting image optimization..."

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick not found. Installing..."
    brew install imagemagick
fi

# Create optimized images directory
mkdir -p lib/assets/images/optimized

# Optimize large images
echo "📦 Optimizing large images..."

# Optimize dj.png (1.0M -> target ~200KB)
if [ -f "lib/assets/images/dj.png" ]; then
    convert "lib/assets/images/dj.png" -resize 800x600 -quality 85 "lib/assets/images/optimized/dj_optimized.png"
    echo "✅ Optimized dj.png"
fi

# Optimize default_featured.jpg (126K -> target ~50KB)
if [ -f "lib/assets/images/default_featured.jpg" ]; then
    convert "lib/assets/images/default_featured.jpg" -resize 1200x800 -quality 80 "lib/assets/images/optimized/default_featured_optimized.jpg"
    echo "✅ Optimized default_featured.jpg"
fi

# Optimize social media icons (reduce from ~180K each to ~30K each)
if [ -f "lib/assets/images/instagram-black.png" ]; then
    convert "lib/assets/images/instagram-black.png" -resize 200x200 -quality 90 "lib/assets/images/optimized/instagram-black_optimized.png"
    echo "✅ Optimized instagram-black.png"
fi

if [ -f "lib/assets/images/instagram-white.png" ]; then
    convert "lib/assets/images/instagram-white.png" -resize 200x200 -quality 90 "lib/assets/images/optimized/instagram-white_optimized.png"
    echo "✅ Optimized instagram-white.png"
fi

if [ -f "lib/assets/images/twitter-black.png" ]; then
    convert "lib/assets/images/twitter-black.png" -resize 200x200 -quality 90 "lib/assets/images/optimized/twitter-black_optimized.png"
    echo "✅ Optimized twitter-black.png"
fi

if [ -f "lib/assets/images/twitter-white.png" ]; then
    convert "lib/assets/images/twitter-white.png" -resize 200x200 -quality 90 "lib/assets/images/optimized/twitter-white_optimized.png"
    echo "✅ Optimized twitter-white.png"
fi

# Show size comparison
echo ""
echo "📊 Size comparison:"
echo "Original sizes:"
ls -lh lib/assets/images/*.png lib/assets/images/*.jpg 2>/dev/null | grep -E "(dj|default_featured|instagram|twitter)" || true

echo ""
echo "Optimized sizes:"
ls -lh lib/assets/images/optimized/* 2>/dev/null || echo "No optimized files found"

echo ""
echo "🎯 Image optimization complete!"
echo "💡 Replace original files with optimized versions for better performance" 