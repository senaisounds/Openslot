# 📱 iPad 13" App Store Screenshot Guide

## 🎯 App Store Requirements

### **Required Dimensions:**
- **iPad 13":** 2048 x 2732px (portrait) or 2732 x 2048px (landscape)
- **Format:** PNG or JPEG
- **Quantity:** 3-10 screenshots required
- **File size:** Max 8MB per screenshot

## 🚀 Quick Start Instructions

### **1. Simulator Setup ✅**
```bash
# iPad Pro 13" simulator is already running
# Device ID: 05675DE2-11B6-4F3D-BFF9-E7E917FB4983
```

### **2. App Launch ✅**
```bash
# Flutter app is launching on iPad simulator
# Wait for app to fully load before capturing
```

### **3. Capture Screenshots**
```bash
# Run the automated screenshot script
./scripts/capture_ipad_screenshots.sh
```

## 📸 Recommended Screenshot Sequence

### **Screenshot 1: Home/Discovery Screen**
- **Purpose:** Show event discovery functionality
- **Key elements:** Event cards, search, location-based results
- **Message:** "Discover amazing events near you"

### **Screenshot 2: Map View**
- **Purpose:** Highlight location-based features
- **Key elements:** Map with event pins, current location
- **Message:** "Find events on an interactive map"

### **Screenshot 3: Event Details**
- **Purpose:** Show reservation and event information
- **Key elements:** Event info, reserve button, pricing, attendees
- **Message:** "Easy reservation system"

### **Screenshot 4: User Profile**
- **Purpose:** Demonstrate user features
- **Key elements:** Profile, saved events, hosting capabilities
- **Message:** "Personalized experience for every user"

### **Screenshot 5: Search & Filters**
- **Purpose:** Show search capabilities
- **Key elements:** Search bar, filters, categories
- **Message:** "Find exactly what you're looking for"

## 🎨 Screenshot Best Practices

### **Visual Guidelines:**
- ✅ **High contrast** - Clear, readable text
- ✅ **Real content** - Use actual event data, not placeholder text
- ✅ **Proper spacing** - Ensure UI elements aren't crowded
- ✅ **Good lighting** - Use light mode for better visibility
- ✅ **Consistent styling** - Maintain brand colors and fonts

### **Content Guidelines:**
- ✅ **Diverse events** - Show variety (music, comedy, poetry, etc.)
- ✅ **Real locations** - Use actual city names and venues
- ✅ **Appropriate content** - Family-friendly event examples
- ✅ **Clear CTAs** - Highlight action buttons and navigation

## 🔧 Technical Setup

### **Current Configuration:**
```
✅ iPad Pro 13-inch (M4) Simulator
✅ Device ID: 05675DE2-11B6-4F3D-BFF9-E7E917FB4983
✅ Flutter app configured for iPad layout
✅ Production-ready build settings
```

### **Screenshot Capture Method:**
```bash
# Automated via script
xcrun simctl io [DEVICE_ID] screenshot filename.png

# Manual via Simulator menu
Device > Screenshot (Cmd+S)
```

## 📊 Quality Checklist

### **Before Submitting:**
- [ ] **Dimensions correct** (2048x2732 or 2732x2048)
- [ ] **File size under 8MB** per screenshot
- [ ] **High resolution** and crisp quality
- [ ] **No simulator UI** visible in screenshots
- [ ] **Real, appropriate content** displayed
- [ ] **Key features highlighted** across all screenshots
- [ ] **Consistent branding** and visual style

### **Content Verification:**
- [ ] **No placeholder text** ("Lorem ipsum", "Sample Event")
- [ ] **Appropriate event names** and descriptions
- [ ] **Real venue names** and locations
- [ ] **Professional imagery** and design
- [ ] **Clear call-to-action** buttons visible

## 🎯 App Store Optimization

### **Screenshot Titles (Optional):**
1. "Discover Local Events"
2. "Find Events Near You"
3. "Easy Event Reservations"
4. "Your Personalized Profile"
5. "Advanced Search & Filters"

### **Key Features to Highlight:**
- 🗺️ **Location-based discovery**
- 🎫 **One-tap reservations**
- 👥 **Social event features**
- 🔍 **Smart search and filtering**
- 📱 **Beautiful, intuitive design**

## 🚀 Next Steps

1. **Wait for app to fully load** on iPad simulator
2. **Navigate to each screen** you want to capture
3. **Run screenshot script** or capture manually
4. **Review dimensions** and quality
5. **Upload to App Store Connect**

## 📞 Troubleshooting

### **If app doesn't load:**
```bash
# Restart Flutter app
flutter clean && flutter run -d "iPad Pro 13-inch (M4)"
```

### **If simulator is slow:**
```bash
# Restart simulator
xcrun simctl shutdown all
xcrun simctl boot "05675DE2-11B6-4F3D-BFF9-E7E917FB4983"
```

### **If dimensions are wrong:**
- Check simulator device type (must be iPad Pro 13")
- Ensure app is in correct orientation
- Use `identify` command to verify dimensions

---

**🎉 You're ready to capture professional App Store screenshots for your iPad 13" submission!**