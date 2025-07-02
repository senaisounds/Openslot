import 'package:latlong2/latlong.dart';

// List of available cities
const List<String> cities = [
  'Near Me',
  'New York City',
  'Los Angeles',
  'Austin',
  'Pittsburgh',
  'London',
  'Sacramento',
  'San Diego'
];

// City coordinates mapping
final Map<String, LatLng> cityCoordinates = {
  'New York City': const LatLng(40.7128, -74.0060),
  'Los Angeles': const LatLng(34.0522, -118.2437),
  'Austin': const LatLng(30.2672, -97.7431),
  'Pittsburgh': const LatLng(40.4406, -79.9959),
  'London': const LatLng(51.5074, -0.1278),
  'Sacramento': const LatLng(38.5816, -121.4944),
  'San Diego': const LatLng(32.7157, -117.1611),
}; 