import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HelpNotification extends StatelessWidget {
  const HelpNotification({super.key, required this.data, required this.id});
  final String id;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final volunteerInfo = data['volunteer'];
    final isVerified = data['status'] == 'verified';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message Section
            Text(
              data['message'],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const Divider(color: Colors.grey),

            // Volunteer Information
            if (volunteerInfo != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Volunteer Info:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text("Name: ${volunteerInfo['name']}"),
                  Text("Phone: ${volunteerInfo['phone']}"),
                  Text("Rating: ${volunteerInfo['rating']}"),
                  const SizedBox(height: 8),
                ],
              ),

            // Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd-MM-yyyy hh:mm a')
                      .format(data['timestamp'].toDate()),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Divider(color: Colors.grey),

            // Action Buttons
            if (!isVerified)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildButton(
                    context,
                    label: "Reject",
                    color: Colors.red,
                    onPressed: () => _rejectVolunteer(context),
                  ),
                  const SizedBox(width: 8),
                  _buildButton(
                    context,
                    label: "Verify",
                    color: Colors.green,
                    onPressed: () => _verifyRequest(context),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildButton(
                    context,
                    label: "Completed",
                    color: Colors.green,
                    onPressed: () => _markAsCompleted(context),
                  ),
                  const SizedBox(width: 8),
                  _buildButton(
                    context,
                    label: "Not Completed",
                    color: Colors.red,
                    onPressed: () => _markAsNotCompleted(context),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context,
      {required String label,
      required Color color,
      required VoidCallback onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  void _rejectVolunteer(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('helpRequests')
          .doc(data['requestId'])
          .update({
        'status': 'pending',
        'rejectedVolunteers': FieldValue.arrayUnion([data['volunteerId1']])
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _verifyRequest(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Request verified.")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _markAsCompleted(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => RatingPage(volunteerId1: data['volunteer']['id'])),
    );
  }

  void _markAsNotCompleted(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Status set to completed. Volunteer penalized.")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}

class RatingPage extends StatelessWidget {
  const RatingPage({super.key, required this.volunteerId1});
  final String volunteerId1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rate Volunteer")),
      body: Center(
        child: Text("Rating UI for Volunteer: $volunteerId1"),
      ),
    );
  }
}
