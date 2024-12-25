import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:awn/screens/special_Need_Portal/Edit_HelpRequest.dart';
import 'package:awn/services/auth_services.dart' as auth_services;

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

              return HelpRequestItem(
                requestData: requestData,
                requestId: request.id,
              );
            },
          );
        },
      ),
    );
  }
}

class HelpRequestItem extends StatelessWidget {
  final Map<String, dynamic> requestData;
  final String requestId;

  const HelpRequestItem(
      {super.key, required this.requestData, required this.requestId});

  @override
  Widget build(BuildContext context) {
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
                Text('Status: ${requestData['status'] ?? 'Unknown Status'}'),
                if (requestData['volunteerId1'] != null)
                  Text('Volunteer ID: ${requestData['volunteerId1']}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
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

                        await FirebaseFirestore.instance
                            .collection('helpRequests')
                            .doc(requestId)
                            .delete();

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
                  child: const Text("Delete"),
                ),
                const SizedBox(width: 8),
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
                  child: const Text("Edit"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
