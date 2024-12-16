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
  // Function to handle rejection of a help request
  Future<void> _handleReject(String requestId, Map<String, dynamic> requestData) async {
    bool? confirmReject = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Rejection'),
          content: const Text('Are you sure you want to reject this request?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // If no, close the dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // If yes, proceed with the reject logic
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmReject == true) {
      try {
        List<dynamic> rejectedIds = requestData['rejectedIds'] ?? [];
        rejectedIds.add(requestData['volunteerId1']); // Add volunteerId1 to rejected list

        if (requestData['volunteerId2'] != null && requestData['volunteerId2'] != "") {
          // If volunteerId2 exists, volunteerId1 takes volunteerId2 value and volunteerId2 is set to null
          await FirebaseFirestore.instance.collection('helpRequests').doc(requestId).update({
            'volunteerId1': requestData['volunteerId2'],
            'volunteerId2': null,
            'status': 'accepted',
            'rejectedIds': rejectedIds,
          });
        } else {
          // If volunteerId2 is empty, change status to pending and volunteerId1 is set to null
          await FirebaseFirestore.instance.collection('helpRequests').doc(requestId).update({
            'volunteerId1': null,
            'status': 'pending',
            'rejectedIds': rejectedIds,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You have rejected the help request.'),
        ));
      } catch (e) {
        print("Error rejecting help request: $e");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('An error occurred while rejecting. Please try again.'),
        ));
      }
    }
  }

  // Function to handle when a help request is marked as completed
  Future<void> _handleCompleted(String requestId, Map<String, dynamic> requestData, Map<String, dynamic> volunteerData) async {
    try {
      int? rating = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RatingPage(),
        ),
      );

      if (rating != null) {
        // Update the rating in 'volunteers' collection
        double currentRating = volunteerData['rating'] ?? 0;
        int numberOfRatings = volunteerData['numberOfRatings'] ?? 0;
        double newRating = (currentRating * numberOfRatings + rating) / (numberOfRatings + 1);

        await FirebaseFirestore.instance.collection('volunteers').doc(requestData['volunteerId1']).update({
          'rating': newRating,
          'numberOfRatings': numberOfRatings + 1,
        });

        // Move the request to 'archivedRequests' collection with status 'completed'
        await _archiveRequest(requestId, requestData, 'completed');
      }
    } catch (e) {
      print('Error completing request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to complete. Please try again.'),
        ),
      );
    }
  }

  // Function to handle when a help request is marked as not completed
  Future<void> _handleNotCompleted(String requestId, Map<String, dynamic> requestData, Map<String, dynamic> volunteerData) async {
    try {
      // Calculate new rating (reduce by 2, but ensure it doesn't go below 0)
      double currentRating = volunteerData['rating'] ?? 0;
      int numberOfRatings = volunteerData['numberOfRatings'] ?? 0;
      double newRating = (currentRating * numberOfRatings - 2) / (numberOfRatings + 1); // Apply the formula
      newRating = newRating.clamp(0.0, 5.0); // Ensure rating stays within 0-5 range

      // Update the rating in 'volunteers' collection
      await FirebaseFirestore.instance.collection('volunteers').doc(requestData['volunteerId1']).update({'rating': newRating});

      // Move the request to 'archivedRequests' collection with status 'notcompleted'
      await _archiveRequest(requestId, requestData, 'notcompleted');
    } catch (e) {
      print('Error marking as not completed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update. Please try again.'),
        ),
      );
    }
  }

  // Function to archive a request by moving it to the 'archivedRequests' collection
  Future<void> _archiveRequest(String requestId, Map<String, dynamic> requestData, String status) async {
    try {
      // Update the status of the request
      requestData['status'] = status;

      // Add the request data to 'archivedRequests' collection
      await FirebaseFirestore.instance.collection('archivedRequests').doc(requestId).set(requestData);

      // Delete the request from 'helpRequests' collection
      await FirebaseFirestore.instance.collection('helpRequests').doc(requestId).delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request marked as $status and archived.'),
      ));
    } catch (e) {
      print('Error archiving request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to archive request. Please try again.'),
        ),
      );
    }
  }

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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
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
                                onPressed: () => _handleReject(requestId, requestData),
                                child: const Text('Reject'),
                              ),
                            ],
                            if (requestData['status'] == 'verified') ...[
                              ElevatedButton(
                                onPressed: () => _handleCompleted(requestId, requestData, volunteerData),
                                child: const Text('Completed'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _handleNotCompleted(requestId, requestData, volunteerData),
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