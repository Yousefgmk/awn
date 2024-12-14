import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awn/services/auth_services.dart' as auth_services;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

// Assuming you have this rating page
import 'package:awn/screens/special_Need_Portal/rating_Page.dart';

class NotificationsList extends StatefulWidget {
  const NotificationsList({super.key});

  @override
  State<NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends State<NotificationsList> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('helpRequests')
          .where('specialNeedId', isEqualTo: auth_services.currentUid)
          .where('status', whereIn: ['accepted', 'verified']).snapshots(),
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
              "No accepted or verified help requests found",
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

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('volunteers')
                  .doc(requestData['volunteerId1'])
                  .get()
                  .catchError((error) {
                print('Error fetching volunteer data: $error');
                throw error;
              }),
              builder: (context, volunteerSnapshot) {
                if (volunteerSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (volunteerSnapshot.hasError) {
                  print('Volunteer snapshot error: ${volunteerSnapshot.error}');
                  return ListTile(
                    title: Text(requestData['type'] ?? 'Unknown Type'),
                    subtitle: const Text('Error fetching volunteer data'),
                  );
                }

                if (!volunteerSnapshot.hasData) {
                  print('No volunteer data found');
                  return ListTile(
                    title: Text(requestData['type'] ?? 'Unknown Type'),
                    subtitle: const Text('Volunteer data not found'),
                  );
                }

                Map<String, dynamic> volunteerData =
                    volunteerSnapshot.data!.data() as Map<String, dynamic>;

                print('Volunteer data: $volunteerData');

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
                    // Changed from ListTile to Column
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        // Moved ListTile here
                        title: Text(requestData['type'] ?? 'Unknown Type'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: $formattedDateTime'),
                            Text(
                                'Description: ${requestData['description'] ?? ''}'),
                            SizedBox(
                              height: 150,
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: location,
                                  zoom: 14.0,
                                ),
                                markers: {
                                  Marker(
                                    markerId:
                                        const MarkerId("helpRequestLocation"),
                                    position: location,
                                  ),
                                },
                              ),
                            ),
                            Text(
                                'Status: ${requestData['status'] ?? 'Unknown Status'}'),
                            Text('Volunteer Name: ${volunteerData['name']}'),
                            Text(
                                'Volunteer Phone: ${volunteerData['phoneNumber']}'),
                            Text(
                                'Volunteer Rating: ${volunteerData['rating'] ?? 'Not Rated'}'),
                          ],
                        ),
                      ),
                      Padding(
                        // Added Padding for the buttons
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (requestData['status'] == 'accepted') ...[
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('helpRequests')
                                        .doc(requestId)
                                        .update({'status': 'verified'});
                                  } catch (e) {
                                    print('Error verifying request: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Failed to verify. Please try again.'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Verify'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    List<dynamic> rejectedIds =
                                        requestData['rejectedIds'] ?? [];
                                    rejectedIds
                                        .add(requestData['volunteerId1']);

                                    await FirebaseFirestore.instance
                                        .collection('helpRequests')
                                        .doc(requestId)
                                        .update({
                                      'status': 'pending',
                                      'volunteerId1': null,
                                      'rejectedIds': rejectedIds,
                                    });
                                  } catch (e) {
                                    print('Error rejecting request: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Failed to reject. Please try again.'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Reject'),
                              ),
                            ],
                            if (requestData['status'] == 'verified') ...[
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    int? rating = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RatingPage(),
                                      ),
                                    );

                                    if (rating != null) {
                                      await FirebaseFirestore.instance
                                          .collection('helpRequests')
                                          .doc(requestId)
                                          .update({'status': 'completed'});

                                      double currentRating =
                                          volunteerData['rating'] ?? 0;
                                      int numberOfRatings =
                                          volunteerData['numberOfRatings'] ?? 0;

                                      double newRating =
                                          (currentRating * numberOfRatings +
                                                  rating) /
                                              (numberOfRatings + 1);

                                      await FirebaseFirestore.instance
                                          .collection('volunteers')
                                          .doc(requestData['volunteerId1'])
                                          .update({
                                        'rating': newRating,
                                        'numberOfRatings': numberOfRatings + 1,
                                      });
                                    }
                                  } catch (e) {
                                    print('Error completing request: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Failed to complete. Please try again.'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Completed'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('helpRequests')
                                        .doc(requestId)
                                        .update({'status': 'notcompleted'});

                                    double currentRating =
                                        volunteerData['rating'] ?? 0;
                                    currentRating -= 2;

                                    await FirebaseFirestore.instance
                                        .collection('volunteers')
                                        .doc(requestData['volunteerId1'])
                                        .update({'rating': currentRating});
                                  } catch (e) {
                                    print('Error marking as not completed: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Failed to update. Please try again.'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Not Completed'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
