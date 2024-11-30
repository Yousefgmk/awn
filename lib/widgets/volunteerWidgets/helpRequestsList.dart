import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awn/services/auth_services.dart' as auth_services;

class HelpRequestsList extends StatefulWidget {
  const HelpRequestsList({Key? key});

  @override
  State<HelpRequestsList> createState() => _HelpRequestsListState();
}

class _HelpRequestsListState extends State<HelpRequestsList> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('helpRequests')
          .where('status', isEqualTo: 'pending') // Show only pending requests
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
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
    return Card(
      child: ListTile(
        title: Text(requestData['type'] ?? 'Unknown Type'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${requestData['date'] ?? 'Unknown Date'}'),
            Text('Description: ${requestData['description'] ?? ''}'),
            Text(
                'Location: ${requestData['location'] ?? 'Unknown Location'}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            try {
              // Update the request status to 'accepted' and add the volunteer ID
              await FirebaseFirestore.instance
                  .collection('helpRequests')
                  .doc(requestId)
                  .update({
                'status': 'accepted',
                'volunteerId': auth_services.currentUid,
              });
            } catch (e) {
              print("Error accepting help request: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("An error occurred. Please try again.")),
              );
            }
          },
          child: const Text("Accept"),
        ),
      ),
    );
  }
}