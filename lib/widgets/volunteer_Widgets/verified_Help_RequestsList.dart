import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awn/services/auth_services.dart' as auth_services;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class VerifiedHelpRequests extends StatefulWidget {
  const VerifiedHelpRequests({super.key});

  @override
  State<VerifiedHelpRequests> createState() => _VerifiedHelpRequestsState();
}

class _VerifiedHelpRequestsState extends State<VerifiedHelpRequests> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('helpRequests')
          .where('volunteerId', isEqualTo: auth_services.currentUid)
          .where('status', isEqualTo: 'verified')
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
                color: Colors.black54,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No verified help requests found",
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
            String requestId = request.id;
            Map<String, dynamic> requestData =
                request.data() as Map<String, dynamic>;

            print('Request data: ${request.data()}');

            String formattedDateTime = requestData['date'] != null
                ? DateFormat('yyyy-MM-dd HH:mm').format(
                    (requestData['date'] as Timestamp).toDate())
                : 'Unknown Date';

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
                    SizedBox(
                      height: 150,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: location,
                          zoom: 14.0,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId("helpRequestLocation"),
                            position: location,
                          ),
                        },
                      ),
                    ),
                    Text(
                        'Status: ${requestData['status'] ?? 'Unknown Status'}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}