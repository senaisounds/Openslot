#!/bin/bash

# iPad 13" Screenshot Capture Script for App Store
# This script captures screenshots in the required App Store dimensions

set -e

echo "📱 Capturing iPad 13\" Screenshots for App Store..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Required iPad 13" dimensions for App Store
# 2048 x 2732px, 2732 x 2048px, 2048 x 2732px or 2732 x 2048px

IPAD_PRO_13_ID="05675DE2-11B6-4F3D-BFF9-E7E917FB4983"

# Check if simulator is booted
print_status "Checking iPad Pro 13\" simulator status..."
SIMULATOR_STATUS=$(xcrun simctl list devices | grep "$IPAD_PRO_13_ID" | grep -o "Booted\|Shutdown")

if [ "$SIMULATOR_STATUS" != "Booted" ]; then
    print_status "Booting iPad Pro 13\" simulator..."
    xcrun simctl boot "$IPAD_PRO_13_ID"
    sleep 5
fi

print_success "iPad Pro 13\" simulator is ready"

# Create screenshots directory
mkdir -p screenshots/ipad_13_inch
cd screenshots/ipad_13_inch

print_status "Capturing screenshots..."

# Function to capture screenshot
capture_screenshot() {
    local filename=$1
    local description=$2
    
    print_status "Capturing: $description"
    xcrun simctl io "$IPAD_PRO_13_ID" screenshot "$filename.png"
    
    # Get image dimensions
    if command -v identify &> /dev/null; then
        local dimensions=$(identify "$filename.png" | cut -d' ' -f3)
        print_success "Captured $filename.png ($dimensions)"
    else
        print_success "Captured $filename.png"
    fi
    
    echo "   📝 $description"
    echo ""
}

print_warning "MANUAL STEPS REQUIRED:"
echo "1. Make sure the Flutter app is running on the iPad simulator"
echo "2. Navigate through different screens for variety"
echo "3. Press ENTER after each screen is ready for screenshot"
echo ""

# Capture different screens
echo "📱 Ready to capture screenshots..."
echo "Press ENTER when the HOME SCREEN is ready..."
read
capture_screenshot "01_home_screen" "Home screen showing event discovery"

echo "Press ENTER when the MAP VIEW is ready..."
read
capture_screenshot "02_map_view" "Map view showing nearby events"

echo "Press ENTER when an EVENT DETAILS page is ready..."
read
capture_screenshot "03_event_details" "Event details and reservation interface"

echo "Press ENTER when the PROFILE PAGE is ready..."
read
capture_screenshot "04_profile_page" "User profile and settings"

echo "Press ENTER when the SEARCH/FILTER screen is ready..."
read
capture_screenshot "05_search_filter" "Search and filter functionality"

# Check final dimensions
print_status "Verifying screenshot dimensions..."

for file in *.png; do
    if command -v identify &> /dev/null; then
        dimensions=$(identify "$file" | cut -d' ' -f3)
        width=$(echo $dimensions | cut -d'x' -f1)
        height=$(echo $dimensions | cut -d'x' -f2)
        
        # Check if dimensions match App Store requirements
        if [[ ($width -eq 2048 && $height -eq 2732) || ($width -eq 2732 && $height -eq 2048) ]]; then
            print_success "$file - $dimensions ✓ (App Store compliant)"
        else
            print_warning "$file - $dimensions (may need resizing)"
        fi
    fi
done

echo ""
print_success "Screenshot capture complete!"
echo ""
echo "📁 Screenshots saved to: $(pwd)"
echo "📱 App Store Requirements:"
echo "   • iPad 13\": 2048 x 2732px or 2732 x 2048px"
echo "   • 3-10 screenshots required"
echo "   • Show key app features"
echo ""
echo "🔄 Next steps:"
echo "   1. Review captured screenshots"
echo "   2. Retake any if needed"
echo "   3. Upload to App Store Connect"

cd ../..