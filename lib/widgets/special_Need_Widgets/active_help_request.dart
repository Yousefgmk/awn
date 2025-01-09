import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:awn/screens/special_Need_Portal/rating_page.dart';
import 'package:awn/services/entity_management_services.dart' as entity_services;
import 'package:awn/services/notification_services.dart' as notification_services;

class ActiveHelpRequest extends StatelessWidget {
  final QueryDocumentSnapshot request;

  const ActiveHelpRequest({
    super.key,
    required this.request,
  });

  Future<void> _handleReject(
    String requestId,
    Map<String, dynamic> requestData,
    BuildContext context,
  ) async {
    bool? confirmReject = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Rejection'),
          content: const Text('Are you sure you want to reject this request?'),
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

    if (confirmReject == true) {
      try {
        await FirebaseFirestore.instance
            .collection('volunteers')
            .doc(requestData['volunteerId1'])
            .update({
          'isInvolved': false,
        });
        List<dynamic> rejectedIds = requestData['rejectedIds'] ?? [];
        rejectedIds.add(// Add volunteerId1 to rejected list
          requestData['volunteerId1'],
        );

        if (requestData['volunteerId2'] != null &&
            requestData['volunteerId2'] != "") {
          // If volunteerId2 exists, volunteerId1 takes volunteerId2 value and volunteerId2 is set to null
          await FirebaseFirestore.instance
              .collection('helpRequests')
              .doc(requestId)
              .update({
            'volunteerId1': requestData['volunteerId2'],
            'volunteerId2': null,
            'status': 'Accepted',
            'rejectedIds': rejectedIds,
          }); //!
        } else {
          // If volunteerId2 is empty, change status to pending and volunteerId1 is set to null
          await FirebaseFirestore.instance
              .collection('helpRequests')
              .doc(requestId)
              .update({
            'volunteerId1': null,
            'status': 'Pending',
            'rejectedIds': rejectedIds,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You have rejected the help request.'),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('An error occurred while rejecting. Please try again.'),
        ));
      }
    }
  }

  Future<void> _handleCompleted(
    String requestId,
    Map<String, dynamic> requestData,
    Map<String, dynamic> volunteerData,
    BuildContext context,
  ) async {
    try {
      double? rating = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RatingPage(),
        ),
      );

      if (rating != null) {
        double currentRating = volunteerData['rating'].toDouble() ?? 0;
        int numberOfRatings = volunteerData['numberOfRatings'].toInt() ?? 0;
        double newRating =
            (currentRating * numberOfRatings + rating) / (numberOfRatings + 1);

        await FirebaseFirestore.instance
            .collection('volunteers')
            .doc(requestData['volunteerId1'])
            .update({
          'rating': newRating,
          'numberOfRatings': numberOfRatings + 1,
          'isInvolved': false
        });

        await notification_services.sendNotification(
          requestData['volunteerId1'],
          true,
          "Thank You For the Help!",
          "Open the app to check your new rating.",
        );

        if(requestData['volunteerId2'] != null && requestData['volunteerId2'] != "") {
          await FirebaseFirestore.instance
            .collection('volunteers')
            .doc(requestData['volunteerId2'])
            .update({
            'isInvolved': false
          });
        }

        await _archiveRequest(requestId, requestData, 'completed', context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to complete. Please try again.'),
        ),
      );
    }
  }

  Future<void> _handleNotCompleted(
    String requestId,
    Map<String, dynamic> requestData,
    Map<String, dynamic> volunteerData,
    BuildContext context,
  ) async {
    try {
      double currentRating = volunteerData['rating'].toDouble() ?? 0;
      int numberOfRatings = volunteerData['numberOfRatings'].toInt() ?? 0;
      double newRating =
          (currentRating * numberOfRatings - 2) / (numberOfRatings);
      newRating = newRating.clamp(0.0, 5.0);

      await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(requestData['volunteerId1'])
          .update({'rating': newRating, 'isInvolved': false});

      if(requestData['volunteerId2'] != null && requestData['volunteerId2'] != "") {
          await FirebaseFirestore.instance
            .collection('volunteers')
            .doc(requestData['volunteerId2'])
            .update({
            'isInvolved': false
          });
      }

      await _archiveRequest(requestId, requestData, 'notcompleted', context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update. Please try again.'),
        ),
      );
    }
  }

  Future<void> _archiveRequest(
    String requestId,
    Map<String, dynamic> requestData,
    String status,
    BuildContext context,
  ) async {
    try {
      requestData['status'] = status;

      await FirebaseFirestore.instance
          .collection('archivedRequests')
          .doc(requestId)
          .set(requestData);

      await entity_services.deleteHelpRequest(requestId);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request marked as $status and archived.'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to archive request. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String requestId = request.id;
    Map<String, dynamic> requestData = request.data() as Map<String, dynamic>;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('volunteers')
          .doc(requestData['volunteerId1'])
          .get()
          .catchError((error) {
        throw error;
      }),
      builder: (context, volunteerSnapshot) {
        if (volunteerSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (volunteerSnapshot.hasError) {
          return ListTile(
            title: Text(requestData['type'] ?? 'Unknown Type'),
            subtitle: const Text('Error fetching volunteer data'),
          );
        }

        if (!volunteerSnapshot.hasData) {
          return ListTile(
            title: Text(requestData['type'] ?? 'Unknown Type'),
            subtitle: const Text('Volunteer data not found'),
          );
        }

        Map<String, dynamic> volunteerData =
            volunteerSnapshot.data!.data() as Map<String, dynamic>;

        String formattedDateTime = requestData['date'] != null
            ? DateFormat('yyyy-MM-dd HH:mm')
                .format((requestData['date'] as Timestamp).toDate())
            : 'Unknown Date';

        String rating = volunteerData['rating'] == 0
            ? 'Not Rated'
            : volunteerData['rating'].toStringAsFixed(2);

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
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requestData['type'] ?? 'Unknown Type',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Divider(),
                    Text(
                      'Status: ${requestData['status'] ?? 'Unknown Status'}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                    Text('Volunteer Name: ${volunteerData['name']}'),
                    Text('Volunteer Phone: ${volunteerData['phoneNumber']}'),
                    Text('Volunteer Rating: $rating'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (requestData['status'] == 'Accepted') ...[
                      ElevatedButton(
                        onPressed: () =>
                            _handleReject(requestId, requestData, context),
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('helpRequests')
                                .doc(requestId)
                                .update({'status': 'Assigned'});
                            await notification_services.sendNotification(
                              requestData['volunteerId1'],
                              true,
                              "You're Assigned",
                              "The request owner has accepted your help. Thank you!",
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Failed to verify. Please try again.'),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Assign',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    if (requestData['status'] == 'Assigned') ...[
                      ElevatedButton(
                        onPressed: () => _handleNotCompleted(
                          requestId,
                          requestData,
                          volunteerData,
                          context,
                        ),
                        child: const Text(
                          'Not Completed',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _handleCompleted(
                          requestId,
                          requestData,
                          volunteerData,
                          context,
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
  }
}
