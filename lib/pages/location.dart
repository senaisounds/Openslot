import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:slotted/common/colors.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({
    super.key,
    required this.onPicked,
    this.eventLocation,
  });

  final Function(Map<String, dynamic>) onPicked;
  final LatLong? eventLocation;

  @override
  LocationPageState createState() => LocationPageState();
}

class LocationPageState extends State<LocationPage> {
  @override
  Widget build(BuildContext context) {
    // get current device location
    return FutureBuilder(
      future: Geolocator.getCurrentPosition(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
              strokeCap: StrokeCap.round,
              backgroundColor: CupertinoColors.systemOrange,
              // strokeAlign: -8,
              strokeWidth: 5,
              color: slottedOrange,
            ),
          );
        }
        return CupertinoPageScaffold(
          resizeToAvoidBottomInset: false,
          navigationBar: CupertinoNavigationBar(
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(CupertinoIcons.back),
            ),
            backgroundColor: CupertinoColors.systemBackground,
            middle: const Text(
              'Pick Location',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: slottedOrange),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Material(
              child: MapLocationPicker(
                bottomCardIcon: const Icon(
                  CupertinoIcons.map_pin_ellipse,
                  color: Colors.orange,
                ),
                hideBackButton: true,
                hideMoreOptions: true,
                hideMapTypeButton: true,
                mapType: MapType.hybrid,
                bottomCardMargin: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                currentLatLng: widget.eventLocation != null
                    ? LatLng(widget.eventLocation!.latitude,
                        widget.eventLocation!.longitude)
                    : LatLng(snapshot.data?.latitude ?? 0,
                        snapshot.data?.longitude ?? 0),
                apiKey: 'AIzaSyDoudXh0qMiSd_H9pXAv5YChAzu1_B0EP0',
                onNext: (result) {
                  final latlng = LatLng(result!.geometry.location.lat,
                      result.geometry.location.lng);
                  widget.onPicked({
                    'address': result.formattedAddress!,
                    'latlng': latlng,
                  });
                },
              ),
              // child: FlutterLocationPicker(
              //   initZoom: 11,
              //   minZoomLevel: 4,
              //   maxZoomLevel: 16,
              //   // urlTemplate:
              //   //     'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}@2x.png?key=v3T3esg2Q6m7thCB68mu',
              //   // urlTemplate:
              //   //     'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=v3T3esg2Q6m7thCB68mu',
              //   trackMyPosition: true,
              //   onPicked: widget.onPicked,
              //   onChanged: (pickedData) {
              //     print(pickedData.address);
              //     print(pickedData.latLong.latitude);
              //     print(pickedData.latLong.longitude);
              //   },
              // ),
            ),
          ),
        );
      },
    );
  }
}
