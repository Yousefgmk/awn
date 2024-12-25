import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'package:awn/services/entity_management_services.dart'
    as entity_services;

class HelpRequest extends StatefulWidget {
  const HelpRequest(
      {super.key, required this.id, required this.helpRequestData});
  final String id;
  final Map<String, dynamic> helpRequestData;

  @override
  State<HelpRequest> createState() => _HelpRequestState();
}

class _HelpRequestState extends State<HelpRequest> {
  String? formattedAddress = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Text(
                  "Help Request",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      "Type: ",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.start,
                    ),
                    Expanded(
                      child: Text(
                        widget.helpRequestData['type'],
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      "Description: ",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.start,
                    ),
                    Expanded(
                      child: Text(
                        widget.helpRequestData['description'],
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      "Status: ",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.start,
                    ),
                    Text(
                      widget.helpRequestData['status'],
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      "Timestamp: ",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      DateFormat('dd-MM-yyyy   hh:mm a')
                          .format(widget.helpRequestData['date'].toDate()),
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(5),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    height: 150,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                            widget.helpRequestData['location'].latitude,
                            widget.helpRequestData['location'].longitude),
                        zoom: 12,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('marker_1'),
                          position: LatLng(
                              widget.helpRequestData['location']  .latitude,
                              widget.helpRequestData['location'].longitude),
                        ),
                      },
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      "Address: ",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.start,
                    ),
                    Expanded(
                      child: Text(
                        "$formattedAddress",
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: const Text(
                            "Are you sure you want to delete this help request?",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  await entity_services
                                      .deleteHelpRequest(widget.id);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("$e")));
                                }
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                "Confirm",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  label: const Text(
                    "Delete",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}