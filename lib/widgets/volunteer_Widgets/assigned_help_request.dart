import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:awn/services/auth_services.dart' as auth_services;
import 'package:awn/services/notification_services.dart' as notification_services;

class AssignedHelpRequest extends StatelessWidget {
  final QueryDocumentSnapshot request;

  const AssignedHelpRequest({
    super.key,
    required this.request,
  });

  Future<void> _handleWithdraw(
    String requestId,
    Map<String, dynamic> requestData,
    BuildContext context,
  ) async {
    bool? confirmWithdraw = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Withdrawal'),
          content: const Text(
              'Are you sure you want to withdraw from this request?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmWithdraw == true) {
      try {
        // penalty for withdrawal
        DocumentSnapshot<Map<String, dynamic>> volunteerData =
            await FirebaseFirestore.instance
                .collection('volunteers')
                .doc(auth_services.currentUid)
                .get();
        double currentRating = volunteerData['rating'].toDouble() ?? 0;
        int numberOfRatings = volunteerData['numberOfRatings'].toInt() ?? 0;
        double newRating =
            (currentRating * numberOfRatings - 1) / (numberOfRatings);
        newRating = newRating.clamp(0.0, 5.0);
        await FirebaseFirestore.instance
            .collection('volunteers')
            .doc(requestData['volunteerId1'])
            .update({'rating': newRating});

        if (requestData['volunteerId2'] != null &&
            requestData['volunteerId2'] != "") {
          // If volunteerId2 exists, volunteerId2 takes volunteerId1 value and volunteerId2 is set to ""
          await FirebaseFirestore.instance
              .collection('helpRequests')
              .doc(requestId)
              .update({
            'volunteerId1': requestData['volunteerId2'],
            'volunteerId2': "",
            'status': 'Accepted',
            'rejectedIds': FieldValue.arrayUnion([auth_services.currentUid])
          });
          await notification_services.sendNotification(
            requestData['specialNeedId'],
            false,
            "Volunteer Withdrew",
            "A new volunteer is ready to help. Open the app to respond.",
          );
        } else {
          // If volunteerId2 is empty, change status to pending and volunteerId1 is set to ""
          await FirebaseFirestore.instance
              .collection('helpRequests')
              .doc(requestId)
              .update({
            'volunteerId1': "",
            'status': 'Pending',
            'rejectedIds': FieldValue.arrayUnion([auth_services.currentUid])
          });
          await notification_services.sendNotification(
            requestData['specialNeedId'],
            false,
            "Volunteer Withdrew",
            "No new volunteer yet. Check the app for updates.",
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You have withdrawn from the help request.'),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('An error occurred while withdrawing. Please try again.'),
        ));
      }
    }
  }

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
            const SizedBox(height: 12),
            Text(
              'Status: ${requestData['status'] ?? 'Unknown Status'}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Withdraw Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: DateTime.now().isBefore(requestData['date'].toDate())
                  ? [
                      ElevatedButton(
                        onPressed: () =>
                            _handleWithdraw(requestId, requestData, context),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                        ),
                        child: const Text(
                          'Withdraw',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]
                  : [
                      ElevatedButton(
                        onPressed: () {
                          notification_services.sendNotification(
                            requestData['specialNeedId'],
                            false,
                            "Rating Required",
                            "Open the app and rate the previous volunteer.",
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                        ),
                        child: const Text(
                          'Remind for Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
