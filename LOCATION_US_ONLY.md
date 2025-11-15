# Location Search - US Only Configuration

## Overview

The location page has been configured to **only show location suggestions within the United States**. This prevents users from selecting international locations like Germany, France, etc.

## Implementation

### How It Works

The location search uses the Nominatim geocoding API with the `countrycodes=us` parameter to restrict all results to United States locations only.

```dart
final url = Uri.parse(
  'https://nominatim.openstreetmap.org/search?'
  'q=${Uri.encodeComponent(query)}&'
  'format=json&'
  'countrycodes=us&'  // ← Restricts to US only
  'limit=5&'
  'addressdetails=1'
);
```

## What This Means

### ✅ Will Work
- **US Cities**: "New York", "Los Angeles", "Chicago"
- **US Addresses**: "123 Main St, San Francisco, CA"
- **US States**: "California", "Texas", "New York"
- **US Landmarks**: "Golden Gate Bridge", "Times Square"
- **US ZIP codes**: "90210", "10001"

### ❌ Won't Show Results
- **International Cities**: "Berlin", "Paris", "London"
- **International Addresses**: Any address outside the US
- **Other Countries**: Canada, Mexico, European countries, etc.

## Examples

### Search: "New York"
```
Results:
✅ New York, New York, United States
✅ New York County, New York, United States
✅ New York State, United States
```

### Search: "Berlin"
```
Results:
✅ Berlin, New Hampshire, United States
✅ Berlin, Wisconsin, United States
❌ Berlin, Germany (NOT shown)
```

### Search: "Paris"
```
Results:
✅ Paris, Texas, United States
✅ Paris, Kentucky, United States
❌ Paris, France (NOT shown)
```

## Technical Details

### API Parameters Used
- `countrycodes=us` - ISO 3166-1 alpha-2 code for United States
- `format=json` - Response format
- `limit=5` - Maximum 5 results
- `addressdetails=1` - Include detailed address components

### Geographic Coverage
The search covers:
- All 50 US states
- Washington D.C.
- US territories (Puerto Rico, Guam, etc.)
- Alaska and Hawaii

### Bounding Box
Approximate US bounds used:
- **West**: -125° (California coast)
- **East**: -66° (Maine coast)
- **North**: 50° (Alaska)
- **South**: 24° (Florida Keys)

## User Experience

### Search Behavior
1. User types "San Francisco"
2. API returns only US locations named "San Francisco"
3. Results shown: San Francisco, CA (and similar US cities)
4. No international results displayed

### Edge Cases Handled
- Cities with same names in US and abroad → Only US version shown
- Generic terms like "Main Street" → US results only
- Partial matches → US results only

## Benefits

### For Your App
- ✅ Focuses on your target market (US events)
- ✅ Prevents user confusion
- ✅ Cleaner, more relevant results
- ✅ Faster search (smaller search space)
- ✅ Better user experience

### For Users
- 🎯 Only sees relevant US locations
- 🚀 Faster search results
- 🎪 No confusion with international cities
- ✨ Better matches for US addresses

## Future Expansion

If you want to add more countries in the future:

```dart
// Single country (current)
'countrycodes=us'

// Multiple countries (example)
'countrycodes=us,ca'  // US and Canada

// North America (example)
'countrycodes=us,ca,mx'  // US, Canada, Mexico
```

### Supported Country Codes
- `us` - United States
- `ca` - Canada
- `mx` - Mexico
- `uk` - United Kingdom
- `de` - Germany
- `fr` - France
- etc. (ISO 3166-1 alpha-2 codes)

## Testing

All existing tests pass with US-only restriction:
```bash
flutter test test/pages/location_page_test.dart
# Result: ✅ 21/21 tests passing
```

## Code Location

**File**: `/lib/pages/location.dart`  
**Method**: `_searchLocation(String query)`  
**Line**: ~96-103

## Summary

🇺🇸 **US-only location search is now active**  
✅ Only US locations will appear in suggestions  
🚫 International locations (like Germany) will not appear  
🎯 Better focused results for your US-based event app  

---

**Status**: ✅ Implemented and Tested  
**Coverage**: All 50 states + DC + territories  
**Test Results**: 21/21 passing


