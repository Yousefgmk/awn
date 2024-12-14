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
  Future<void> _handleWithdraw(String requestId, Map<String, dynamic> requestData) async {
    bool? confirmWithdraw = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Withdrawal'),
          content: const Text('Are you sure you want to withdraw from this request?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // If no, close the dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // If yes, proceed with the withdraw logic
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmWithdraw == true) {
      try {
        // Perform withdrawal logic
        if (requestData['volunteerId2'] != "") {
          // If volunteerId2 exists, volunteerId1 takes volunteerId2 value and volunteerId2 is set to ""
          await FirebaseFirestore.instance.collection('helpRequests').doc(requestId).update({
            'volunteerId1': requestData['volunteerId2'],
            'volunteerId2': "",
            'status': 'accepted',
            'rejectedVolunteers': FieldValue.arrayUnion([auth_services.currentUid])
          });
        } else {
          // If volunteerId2 is empty, change status to pending and volunteerId1 is set to ""
          await FirebaseFirestore.instance.collection('helpRequests').doc(requestId).update({
            'volunteerId1': "",
            'status': 'pending',
            'rejectedVolunteers': FieldValue.arrayUnion([auth_services.currentUid])
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You have withdrawn from the help request.'),
        ));
      } catch (e) {
        print("Error withdrawing from help request: $e");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('An error occurred while withdrawing. Please try again.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('helpRequests')
          .where('volunteerId1', isEqualTo: auth_services.currentUid)
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
                    Text('Status: ${requestData['status'] ?? 'Unknown Status'}'),
                    // Display message when volunteerId2 is empty
                    if (requestData['status'] == 'accepted' || requestData['status'] == 'verified')
                      if (requestData['volunteerId2'] == "")
                        const Text(
                          "NOTE: You will be a second responder if the first user withdraws.",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                    // Withdraw Button
                    TextButton(
                      onPressed: () => _handleWithdraw(requestId, requestData),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,  // Set the background color here
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),  // Makes the button round
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),  // Add padding for better touch target size
                      ),
                      child: const Text(
                        'Withdraw',
                        style: TextStyle(
                          color: Colors.white,  // White text color
                          fontSize: 16,         // Text size
                          fontWeight: FontWeight.bold,  // Bold text
                        ),
                      ),
                    ),
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
