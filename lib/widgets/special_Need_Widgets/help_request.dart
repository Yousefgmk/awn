import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:awn/screens/special_Need_Portal/edit_help_request.dart';
import 'package:awn/services/entity_management_services.dart' as entity_services;
import 'package:awn/services/notification_services.dart' as notification_services;

class HelpRequest extends StatelessWidget {
  final QueryDocumentSnapshot request;

  const HelpRequest({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    String requestId = request.id;
    Map<String, dynamic> requestData = request.data() as Map<String, dynamic>;

    String formattedDateTime = requestData['date'] != null
        ? DateFormat('yyyy-MM-dd HH:mm')
            .format((requestData['date'] as Timestamp).toDate())
        : 'Unknown Date';

    LatLng location = LatLng(
      requestData['location'].latitude,
      requestData['location'].longitude,
    );

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requestData['type'] ?? 'Unknown Type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Divider(),
                Text(
                  'Status: ${requestData['status'] ?? 'Unknown Status'}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: $formattedDateTime'),
                Text('Description: ${requestData['description'] ?? ''}'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: location,
                      zoom: 18.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId("helpRequestLocation"),
                        position: location,
                      ),
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    bool? confirmDelete = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Confirm Delete"),
                          content: const Text(
                              "Are you sure you want to delete this help request?"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: const Text("Yes"),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmDelete == true) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('archivedRequests')
                            .doc(requestId)
                            .set(requestData);
                        
                        if(requestData['volunteerId1'] != null && requestData['volunteerId1'] != "") {
                          await notification_services.sendNotification(
                            requestData['volunteerId1'],
                            true,
                            "Request Removed",
                            "This request has been deleted. Explore other opportunities.",
                          );
                        }

                        await entity_services.deleteHelpRequest(requestId);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Request archived successfully."),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Failed to archive. Please try again."),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    "Delete",
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditHelpRequestPage(
                          initialLocation: location,
                          initialDate:
                              (requestData['date'] as Timestamp).toDate(),
                          initialTime: TimeOfDay.fromDateTime(
                              (requestData['date'] as Timestamp).toDate()),
                        ),
                        settings: RouteSettings(arguments: requestId),
                      ),
                    );
                  },
                  child: const Text(
                    "Edit",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
