import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationInput extends StatefulWidget {
  const LocationInput({
    super.key,
    required this.onChanged,
    required this.onLoaded,
  });

  final void Function(double latitude, double longitude) onChanged;
  final void Function(double latitude, double longitude) onLoaded;

  @override
  State<LocationInput> createState() => LocationInputState();
}

class LocationInputState extends State<LocationInput> {
  double? latitude;
  double? longitude;
  Marker? _activeMarker;
  String googleMapsApiKey = 'AIzaSyBGNtLfBQOdXvxGKU57fOrnji0Rm20x5CE';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 60),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await remoteConfig.fetchAndActivate();
    googleMapsApiKey = remoteConfig.getString('maps_api_key');
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();

    setState(() {
      latitude = locationData.latitude;
      longitude = locationData.longitude;
      _activeMarker = Marker(
        markerId: const MarkerId('selectedLocation'),
        position: LatLng(latitude!, longitude!),
      );
    });
    widget.onLoaded(latitude!, longitude!);
    widget.onChanged(latitude!, longitude!);
  }

  String get locationImage {
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=16&size=600x400&maptype=roadmap&markers=color:red%7Clabel:A%7C$latitude,$longitude&key=$googleMapsApiKey';
  }

  void _selectLocation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Location"),
          content: MapDialog(
            initialLatitude: latitude!,
            initialLongitude: longitude!,
            onLocationSelected: (LatLng selectedLocation) {
              setState(() {
                latitude = selectedLocation.latitude;
                longitude = selectedLocation.longitude;
                _activeMarker = Marker(
                  markerId: const MarkerId('selectedLocation'),
                  position: selectedLocation,
                );
              });
              widget.onChanged(
                  selectedLocation.latitude, selectedLocation.longitude);
            },
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text("Done"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void refreshLocation() {
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _selectLocation(context);
      },
      child: latitude != null
          ? Center(
              child: Image.network(
                locationImage,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

class MapDialog extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final Function(LatLng) onLocationSelected;

  const MapDialog({
    required this.initialLatitude,
    required this.initialLongitude,
    required this.onLocationSelected,
    super.key,
  });

  @override
  _MapDialogState createState() => _MapDialogState();
}

class _MapDialogState extends State<MapDialog> {
  late double latitude;
  late double longitude;
  Marker? _activeMarker;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    latitude = widget.initialLatitude;
    longitude = widget.initialLongitude;
    _activeMarker = Marker(
      markerId: const MarkerId('selectedLocation'),
      position: LatLng(latitude, longitude),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(latitude, longitude),
        16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 300,
          height: 300,
          padding: const EdgeInsets.all(10),
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            onTap: (location) {
              setState(() {
                latitude = location.latitude;
                longitude = location.longitude;
                _activeMarker = Marker(
                  markerId: const MarkerId('selectedLocation'),
                  position: LatLng(latitude, longitude),
                );
                widget.onLocationSelected(LatLng(latitude, longitude));
              });
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(latitude, longitude),
              zoom: 16,
            ),
            markers: _activeMarker != null
                ? {
                    _activeMarker!,
                  }
                : {},
          ),
        ),
      ],
    );
  }
}
