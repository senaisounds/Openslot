import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';








/// Simple suggestion model class for addresses
class AddressSuggestion {
  final String text;
  final String id;

  AddressSuggestion({required this.text, required this.id});
  
  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      text: json['text'] as String,
      id: json['id'] as String,
    );
  }
}

class LocationPage extends StatefulWidget {
  final Function(Map<String, dynamic>)? onPicked;
  final LatLng? eventLocation;
  final double? minZoom;
  final double? maxZoom;
  final bool? automaticallyAnimateToCurrentLocation;
  final LatLng? initialCenter;
  final bool? layersButtonEnabled;
  final bool? requiredGPS;

  const LocationPage({
    super.key,
    this.onPicked,
    this.eventLocation,
    this.minZoom,
    this.maxZoom,
    this.automaticallyAnimateToCurrentLocation,
    this.initialCenter,
    this.layersButtonEnabled,
    this.requiredGPS,
  });

  @override
  LocationPageState createState() => LocationPageState();
}

class LocationPageState extends State<LocationPage> with SingleTickerProviderStateMixin {
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with existing location if available
    if (widget.eventLocation != null) {
      _latitudeController.text = widget.eventLocation!.latitude.toString();
      _longitudeController.text = widget.eventLocation!.longitude.toString();
    } else {
      // Default to San Francisco
      _latitudeController.text = '37.7749';
      _longitudeController.text = '-122.4194';
    }
    
    _addressController.text = 'Custom Location';
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _pickLocation() {
    final latitude = double.tryParse(_latitudeController.text);
    final longitude = double.tryParse(_longitudeController.text);
    
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid latitude and longitude')),
      );
      return;
    }
    
    final result = {
      'address': _addressController.text.isNotEmpty 
          ? _addressController.text 
          : 'Custom Location (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})',
      'latlng': LatLng(latitude, longitude),
    };
    
    if (widget.onPicked != null) {
      widget.onPicked!(result);
    }
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Enter Location Coordinates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address/Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _latitudeController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _longitudeController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            const Text(
              'Note: This is a simplified location picker. For a full map interface, please update the location picker dependency.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Pick This Location'),
            ),
          ],
        ),
      ),
    );
  }
}
