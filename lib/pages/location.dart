import 'package:flutter/cupertino.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:slotted/common/colors.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key, required this.onPicked});

  final Function(PickedData) onPicked;

  @override
  LocationPageState createState() => LocationPageState();
}

class LocationPageState extends State<LocationPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        middle: Text(
          'Pick Location',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: slottedOrange),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Material(
          child: FlutterLocationPicker(
            initZoom: 11,
            minZoomLevel: 5,
            maxZoomLevel: 16,
            trackMyPosition: true,
            onPicked: widget.onPicked,
            onChanged: (pickedData) {
              print(pickedData.address);
              print(pickedData.latLong.latitude);
              print(pickedData.latLong.longitude);
            },
          ),
        ),
      ),
    );
  }
}
