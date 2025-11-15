# Location Page - Developer Usage Guide

## Quick Start

### Basic Usage

```dart
Navigator.of(context).push(
  CupertinoPageRoute(
    builder: (context) => LocationPage(
      onPicked: (Map<String, dynamic> picked) {
        final address = picked['address'] as String?;
        final latlng = picked['latlng'] as LatLng?;
        
        // Use the selected location
        setState(() {
          _address = address;
          _coordinates = latlng;
        });
      },
    ),
  ),
);
```

### With Initial Location

```dart
LocationPage(
  onPicked: (picked) {
    // Handle selection
  },
  eventLocation: LatLng(37.7749, -122.4194), // San Francisco
)
```

## Return Data Format

The `onPicked` callback receives a Map with the following structure:

```dart
{
  'address': String,      // Human-readable address
  'latlng': LatLng?,      // Coordinates (latitude/longitude)
}
```

### Examples:

#### When user selects from search suggestions:
```dart
{
  'address': '1600 Amphitheatre Parkway, Mountain View, CA 94043, USA',
  'latlng': LatLng(37.4220, -122.0841)
}
```

#### When user taps on map (mobile):
```dart
{
  'address': 'Golden Gate Park, San Francisco, CA, USA',
  'latlng': LatLng(37.7694, -122.4862)
}
```

#### When geocoding fails (fallback):
```dart
{
  'address': 'Lat: 37.774900, Lng: -122.419400',
  'latlng': LatLng(37.7749, -122.4194)
}
```

## Integration Example (Full)

```dart
class CreateEventPage extends StatefulWidget {
  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final TextEditingController _locationController = TextEditingController();
  LatLng? _eventCoordinates;
  
  Future<void> _selectLocation() async {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => LocationPage(
          onPicked: (Map<String, dynamic> picked) {
            if (!mounted) return;
            
            final address = picked['address'] as String?;
            final latlng = picked['latlng'] as LatLng?;
            
            if (address != null && address.isNotEmpty) {
              setState(() {
                _locationController.text = address;
                _eventCoordinates = latlng;
              });
            }
          },
          eventLocation: _eventCoordinates, // Pre-fill if editing
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            controller: _locationController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Location',
              suffixIcon: IconButton(
                icon: Icon(Icons.location_on),
                onPressed: _selectLocation,
              ),
            ),
            onTap: _selectLocation,
          ),
          
          // Show map preview if coordinates available
          if (_eventCoordinates != null)
            Container(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _eventCoordinates!,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _eventCoordinates!,
                        child: Icon(Icons.location_on, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

## Features Available to Users

### 1. Address Search
- Type any address
- Get real-time suggestions
- Select from dropdown

### 2. Current Location
- Tap location button
- App requests permission (first time)
- Automatically fills in address

### 3. Map Selection (Mobile Only)
- Tap anywhere on map
- See marker at selected position
- Address auto-fills via reverse geocoding

### 4. Coordinate Display
- Shows lat/lng for selected position
- Useful for debugging
- Displayed if reverse geocoding fails

## Error Handling

The page handles various error scenarios gracefully:

```dart
// Permission denied
Exception('Location permissions are denied')

// Permission permanently denied  
Exception('Location permissions are permanently denied')

// Network timeout
// Automatically falls back to coordinate-only display

// Geocoding service unavailable
// Shows fallback suggestions based on input
```

## Best Practices

### 1. Check for mounted state
```dart
LocationPage(
  onPicked: (picked) {
    if (!mounted) return; // Always check
    setState(() {
      // Update state
    });
  },
)
```

### 2. Validate received data
```dart
onPicked: (picked) {
  if (picked.containsKey('address') && picked.containsKey('latlng')) {
    final address = picked['address'] as String?;
    final latlng = picked['latlng'];
    
    if (address != null && address.isNotEmpty) {
      // Process valid data
    }
  }
}
```

### 3. Handle null coordinates
```dart
// Coordinates might be null on web or if geocoding fails
if (latlng != null) {
  // Use coordinates for map display
} else {
  // Still have address text
}
```

### 4. Pre-fill for editing
```dart
LocationPage(
  eventLocation: existingEvent.location, // LatLng from database
  onPicked: (picked) {
    // Update event location
  },
)
```

## Geocoding Service

Uses **Nominatim** (OpenStreetMap):
- Free, no API key needed
- Rate limit: ~1 request/second
- User-Agent header required: 'OpenSlot/1.0'
- Timeout: 5 seconds

### API Endpoints Used:

**Search (autocomplete):**
```
GET https://nominatim.openstreetmap.org/search
  ?q={query}
  &format=json
  &addressdetails=1
  &limit=5
```

**Reverse Geocoding:**
```
GET https://nominatim.openstreetmap.org/reverse
  ?lat={latitude}
  &lon={longitude}
  &format=json
  &addressdetails=1
```

## Platform Differences

### Web
- Text-based search interface
- No interactive map (uses suggestion list)
- Current location via browser API
- Returns address + coordinates

### iOS/Android
- Map-first interface
- Interactive map with tap selection
- Native GPS for current location
- Search overlay on map
- Returns address + coordinates

## Testing Checklist

- [ ] Search returns relevant results
- [ ] Selecting suggestion populates address
- [ ] Current location button works
- [ ] Location permissions requested properly
- [ ] Map tap updates selected location (mobile)
- [ ] Coordinates are accurate
- [ ] Address is human-readable
- [ ] Works offline (shows error gracefully)
- [ ] Pre-fill works when editing
- [ ] Navigation back works properly

## Common Issues & Solutions

### Issue: No search results
**Solution**: Check internet connection, Nominatim might be rate-limited

### Issue: Location permission denied
**Solution**: App shows error dialog, user can manually search instead

### Issue: Coordinates null on web
**Expected**: Web version may not always provide coordinates, address is still available

### Issue: Map not loading
**Solution**: Check internet connection, OpenStreetMap tiles require network

---

**Last Updated**: 2024
**Maintainer**: OpenSlot Development Team

