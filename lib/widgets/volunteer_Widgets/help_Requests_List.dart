import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awn/services/auth_services.dart' as auth_services;
import 'package:awn/widgets/custom_dropdown_button.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class HelpRequestsList extends StatefulWidget {
  const HelpRequestsList({Key? key});

  @override
  State<HelpRequestsList> createState() => _HelpRequestsListState();
}

class _HelpRequestsListState extends State<HelpRequestsList> {
  String? _selectedTypeFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomDropdownButton(
              controller: TextEditingController(),
              selectedDropDownValue: _selectedTypeFilter,
              onChanged: (newValue) {
                setState(() {
                  _selectedTypeFilter = newValue;
                });
              },
              isFilter: true,
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedTypeFilter = null;
                });
              },
              child: const Text("Reset"),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('helpRequests')
                .where('status', whereIn: ['accepted', 'verified', 'pending'])
                .where('volunteerId2', isEqualTo: "")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
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

              return FutureBuilder<DocumentSnapshot>(
                future: auth_services.volunteerData,
                builder: (context, volunteerSnapshot) {
                  if (volunteerSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (volunteerSnapshot.hasError) {
                    return Center(
                        child: Text('Error: ${volunteerSnapshot.error}'));
                  }

                  if (!volunteerSnapshot.hasData) {
                    return const Center(
                      child: Text(
                        "Volunteer data not found.",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  }

                  String volunteerId1 = volunteerSnapshot.data!.id;
                  String volunteerMajor = volunteerSnapshot.data!['major'];

                  List<QueryDocumentSnapshot> allRequests = snapshot.data!.docs;

                  // Filter requests based on additional conditions
                  List<QueryDocumentSnapshot> filteredRequests =
                      allRequests.where((request) {
                    Map<String, dynamic> requestData =
                        request.data() as Map<String, dynamic>;

                    // Check if the request has not been rejected by the current volunteer
                    List<dynamic> rejectedIds =
                        requestData['rejectedIds'] ?? [];
                    if (rejectedIds.contains(volunteerId1)) {
                      return false;
                    }

                    // Check if the requested major matches or is null
                    if (requestData['requestedMajor'] != volunteerMajor &&
                        requestData['requestedMajor'] != null) {
                      return false;
                    }

                    // If the request is accepted, check if the volunteerId1 matches current user's ID
                    if ((requestData['status'] == 'accepted' ||
                            requestData['status'] == 'verified') &&
                        requestData['volunteerId1'] ==
                            auth_services.currentUid) {
                      return false;
                    }

                    // Filter by type if selected
                    if (_selectedTypeFilter != null &&
                        requestData['type'] != _selectedTypeFilter) {
                      return false;
                    }

                    return true;
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredRequests.length,
                    itemBuilder: (context, index) {
                      QueryDocumentSnapshot request = filteredRequests[index];
                      Map<String, dynamic> requestData =
                          request.data() as Map<String, dynamic>;

                      return HelpRequestItem(
                        requestData: requestData,
                        requestId: request.id,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class HelpRequestItem extends StatelessWidget {
  final Map<String, dynamic> requestData;
  final String requestId;

  const HelpRequestItem({
    super.key,
    required this.requestData,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    // Format the date and time (hours and minutes only)
    String formattedDateTime = requestData['date'] != null
        ? DateFormat('yyyy-MM-dd HH:mm')
            .format((requestData['date'] as Timestamp).toDate())
        : 'Unknown Date';

    // Get location as a LatLng (assuming 'location' is a GeoPoint)
    LatLng location = LatLng(
      requestData['location'].latitude,
      requestData['location'].longitude,
    );

    // Check if the status is accepted or verified and volunteerId2 is empty
    bool isSecondResponder = (requestData['status'] == 'accepted' ||
            requestData['status'] == 'verified') &&
        requestData['volunteerId2'] == "";

    return Card(
      child: ListTile(
        title: Text(requestData['type'] ?? 'Unknown Type'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date and Time: $formattedDateTime'),
            Text('Description: ${requestData['description'] ?? ''}'),
            // Display the map
            SizedBox(
              height: 200, // Adjust map height as needed
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

              // Optionally, you can show a success message or perform additional actions
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Help request accepted!"),
              ));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("An error occurred. Please try again.")));
            }
          },
          child: const Text("Accept"),
        ),
      ),
    );
  }
}
