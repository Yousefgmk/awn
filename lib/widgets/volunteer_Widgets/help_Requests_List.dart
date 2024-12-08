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
                .where('status', isEqualTo: 'pending')
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

                  String volunteerId = volunteerSnapshot.data!.id;
                  String volunteerMajor = volunteerSnapshot.data!['major'];

                  List<QueryDocumentSnapshot> filteredRequests = snapshot.data!.docs.where((request) {
                    // Safely cast request.data() to Map<String, dynamic> and check for 'rejectedIds'
                      Map<String, dynamic> requestData = request.data() as Map<String, dynamic>;
                      List<dynamic> rejectedIds = requestData.containsKey('rejectedIds') 
                      ? requestData['rejectedIds'] 
                      : [];
                      return !rejectedIds.contains(volunteerId);
                    }).where((request) {
                      Map<String, dynamic> requestData = request.data() as Map<String, dynamic>;
                      return requestData['requestedMajor'] == volunteerMajor ||
                      requestData['requestedMajor'] == null;
                    }).where((request) {
                      Map<String, dynamic> requestData = request.data() as Map<String, dynamic>;
                      return _selectedTypeFilter == null || requestData['type'] == _selectedTypeFilter;
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
        ? DateFormat('yyyy-MM-dd HH:mm').format(
            (requestData['date'] as Timestamp).toDate())
        : 'Unknown Date';

    // Get location as a LatLng (assuming 'location' is a GeoPoint)
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
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            try {
              await FirebaseFirestore.instance
                  .collection('helpRequests')
                  .doc(requestId)
                  .update({
                'status': 'accepted',
                'volunteerId': auth_services.currentUid,
              });
            } catch (e) {
              print("Error accepting help request: $e");
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