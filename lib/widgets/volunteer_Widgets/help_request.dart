import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'package:awn/services/auth_services.dart' as auth_services;

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

    bool isSecondResponder = (requestData['status'] == 'accepted' ||
            requestData['status'] == 'verified') &&
        requestData['volunteerId2'] == "";

    return Card(
      elevation: 8,
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(requestData['type'] ?? 'Unknown Type', style: TextStyle(fontWeight: FontWeight.bold),),
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
                  "NOTE: You will be a second responder if the first user withdraws.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            try {
              if (requestData['status'] == 'pending') {
                await FirebaseFirestore.instance
                    .collection('helpRequests')
                    .doc(requestId)
                    .update({
                  'status': 'accepted',
                  'volunteerId1': auth_services.currentUid,
                  'volunteerId2': ""
                });
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
          child: const Text("Accept", style: TextStyle(fontWeight: FontWeight.bold),),
        ),
      ),
    );
  }
}