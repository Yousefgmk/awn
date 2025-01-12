import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:awn/services/auth_services.dart' as auth_services;
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

    bool isSecondResponder = (requestData['status'] == 'Accepted' ||
            requestData['status'] == 'Assigned') &&
        requestData['volunteerId2'] == "" &&
        requestData['volunteerId1'] != auth_services.currentUid;

    return Card(
      elevation: 8,
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              requestData['type'] ?? 'Unknown Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Divider(),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date and Time: $formattedDateTime'),
            Text('Description: ${requestData['description'] ?? ''}'),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
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
            // Show note for second responder
            if (isSecondResponder)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "NOTE: Backup Volunteer\nYou will be assigned if the current volunteer withdraws.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: requestData['volunteerId2'] == auth_services.currentUid
            ? ElevatedButton(
                onPressed: () async {
                  FirebaseFirestore.instance
                      .collection('volunteers')
                      .doc(auth_services.currentUid)
                      .update({
                    'isInvolved': false,
                  });
                  if (auth_services.currentUid == requestData['volunteerId2']) {
                    await FirebaseFirestore.instance
                        .collection('helpRequests')
                        .doc(requestId)
                        .update({'volunteerId2': ''});
                  }
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            : requestData['volunteerId1'] == auth_services.currentUid &&
                    requestData['status'] == 'Accepted'
                ? ElevatedButton(
                    onPressed: () async {
                      FirebaseFirestore.instance
                          .collection('volunteers')
                          .doc(auth_services.currentUid)
                          .update({
                        'isInvolved': false,
                      });
                      if (requestData['volunteerId2'] == null ||
                          requestData['volunteerId2'] == "") {
                        await FirebaseFirestore.instance
                            .collection('helpRequests')
                            .doc(requestId)
                            .update({'volunteerId1': '', 'status': 'Pending'});
                      } else {
                        await FirebaseFirestore.instance
                            .collection('helpRequests')
                            .doc(requestId)
                            .update({
                          'volunteerId1': requestData['volunteerId2'],
                          'volunteerId2': ''
                        });
                      }
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () async {
                      try {
                        var volunteerData = await FirebaseFirestore.instance
                            .collection('volunteers')
                            .doc(auth_services.currentUid)
                            .get();
                        if (volunteerData['isInvolved']) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text("You're currently involved in other requests"),
                          ));
                          return;
                        }
                        await FirebaseFirestore.instance
                            .collection('volunteers')
                            .doc(auth_services.currentUid)
                            .update({
                          'isInvolved': true,
                        });
                        if (requestData['status'] == 'Pending') {
                          await FirebaseFirestore.instance
                              .collection('helpRequests')
                              .doc(requestId)
                              .update({
                            'status': 'Accepted',
                            'volunteerId1': auth_services.currentUid,
                            'volunteerId2': ""
                          });
                          await notification_services.sendNotification(
                            requestData['specialNeedId'],
                            false,
                            "Request Accepted",
                            "A volunteer has accepted your request. Open the app to respond.",
                          );
                        } else {
                          await FirebaseFirestore.instance
                              .collection('helpRequests')
                              .doc(requestId)
                              .update({
                            'volunteerId2': auth_services.currentUid,
                          });
                        }
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Help request accepted!"),
                        ));
                      } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("An error occurred. Please try again.")));
                      }
                    },
                    child: const Text(
                      "Accept",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
      ),
    );
  }
}
