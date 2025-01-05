import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:awn/services/auth_services.dart' as auth_services;

FirebaseFirestore firestore = FirebaseFirestore.instance;

Future<void> deleteHelpRequest(String id) async {
  await firestore.collection('helpRequests').doc(id).delete();
}

void submitHelpRequest(
  String type,
  String description,
  double latitude,
  double longitude,
  DateTime selectedDate,
  BuildContext context,
  String? major,
) async {
  try {
    await firestore.collection('helpRequests').add({
      'specialNeedId': auth_services.currentUid,
      'description': description,
      'date': selectedDate,
      'location': GeoPoint(latitude, longitude),
      'status': 'Pending',
      'type': type,
      'requestedMajor': major,
      'volunteerId1' : "",
      'volunteerId2': ""
    });

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Submitted successfully"),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to submit help request: $e"),
      ),
    );
  }
}
