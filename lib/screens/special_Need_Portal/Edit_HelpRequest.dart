import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:time_picker_spinner_pop_up/time_picker_spinner_pop_up.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditHelpRequestPage extends StatefulWidget {
  final LatLng initialLocation;
  final DateTime initialDate;
  final TimeOfDay initialTime;

  const EditHelpRequestPage({
    super.key,
    required this.initialLocation,
    required this.initialDate,
    required this.initialTime,
  });

  @override
  State<EditHelpRequestPage> createState() => _EditHelpRequestPageState();
}

class _EditHelpRequestPageState extends State<EditHelpRequestPage> {
  late GoogleMapController _mapController;
  late LatLng _location;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation;
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      widget.initialTime.hour,
      widget.initialTime.minute,
    );
  }

  void _updateLocation(LatLng newLocation) {
    setState(() {
      _location = newLocation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Edit Help Request"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Card(
              color: Colors.white,
              borderOnForeground: false,
              elevation: 30,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      // Time Picker Section
                      Container(
                        padding: const EdgeInsets.all(5),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TimePickerSpinnerPopUp(
                              mode: CupertinoDatePickerMode.dateAndTime,
                              timeWidgetBuilder: (time) {
                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.8),
                                      width: 1.75,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 10, 12, 10),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${_selectedDate.day.toString()}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year.toString()}  ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              initTime: _selectedDate,
                              minTime: DateTime.now()
                                  .subtract(const Duration(days: 1)),
                              barrierColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              onChange: (dateTime) {
                                setState(() {
                                  _selectedDate = dateTime;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Google Map Section
                      Container(
                        padding: const EdgeInsets.all(5),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: SizedBox(
                          height: 200,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _location,
                              zoom: 14.0,
                            ),
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                            },
                            onTap: _updateLocation,
                            markers: {
                              Marker(
                                markerId: const MarkerId("helpRequestLocation"),
                                position: _location,
                              ),
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final requestId = ModalRoute.of(context)!
                                .settings
                                .arguments as String;

                            await FirebaseFirestore.instance
                                .collection('helpRequests')
                                .doc(requestId)
                                .update({
                              'location': GeoPoint(
                                _location.latitude,
                                _location.longitude,
                              ),
                              'date': Timestamp.fromDate(_selectedDate),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Request updated successfully!'),
                              ),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Failed to update. Please try again.'),
                              ),
                            );
                          }
                        },
                        child: const Text("Save Changes"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
