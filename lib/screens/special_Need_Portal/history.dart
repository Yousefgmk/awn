import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awn/services/auth_services.dart' as auth_services;
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import for Google Maps
import 'package:intl/intl.dart';
class HelpHistory extends StatefulWidget {
  const HelpHistory({super.key});

  @override
  State<HelpHistory> createState() => _HelpHistoryState();
}

class _HelpHistoryState extends State<HelpHistory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help History"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('helpRequests')
            .where('specialNeedId', isEqualTo: auth_services.currentUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No help requests found.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              QueryDocumentSnapshot request = snapshot.data!.docs[index];
              Map<String, dynamic> requestData =
                  request.data() as Map<String, dynamic>;

              return HelpRequestItem(requestData: requestData);
            },
          );
        },
      ),
    );
  }
}

class HelpRequestItem extends StatelessWidget {
  final Map<String, dynamic> requestData;

  const HelpRequestItem({super.key, required this.requestData});

  @override
  Widget build(BuildContext context) {
    // Format the date if it exists
    String formattedDateTime = requestData['date'] != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(
        (requestData['date'] as Timestamp).toDate())
        : 'Unknown Date';

    //  Get location as a LatLng (assuming 'location' is a GeoPoint)
    LatLng location = LatLng(
      requestData['location'].latitude,
      requestData['location'].longitude,
    );

    return Card(
      child: ListTile(
        title: Text(requestData['type'] ?? 'Unknown Type'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: $formattedDateTime'),
            Text('Description: ${requestData['description'] ?? ''}'),
            // Display the map
            SizedBox(
              height: 150, // Adjust map height as needed
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: location,
                  zoom: 14.0, // Adjust zoom as needed
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId("helpRequestLocation"),
                    position: location,
                  ),
                },
              ),
            ),
            Text('Status: ${requestData['status'] ?? 'Unknown Status'}'),
            if (requestData['volunteerId'] != null)
              Text('Volunteer ID: ${requestData['volunteerId']}'),
          ],
        ),
      ),
    );
  }
}