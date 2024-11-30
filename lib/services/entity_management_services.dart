import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:awn/services/auth_services.dart' as auth_services;

FirebaseFirestore firestore = FirebaseFirestore.instance; 
Uuid uuid = const Uuid();

Future<void> 
 deleteHelpRequest(String id) async {
  await firestore.collection('helpRequests').doc(id).delete();
}

Future<void> deleteNotification(String id, String collection) async {
  await firestore.collection(collection).doc(id).delete();
}


Future<void> addItem(
  String type,
  String description,
  int color,
  GeoPoint location,
  BuildContext context,
) async {
  String itemId = uuid.v4();

  try {
    await firestore.collection('items').doc(itemId).set(
      {
        'adminId': auth_services.currentUid,
        'description': description,
        'color': color,
        'date': DateTime.now(),
        'location': location,
        'type': type,
      },
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Added successfully"),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("An error occurred, try again later$e"),
      ),
    );
  }
}

void submitHelpRequest(
  String type,
  String description,
  double latitude,
  double longitude,
  DateTime selectedDate,
  BuildContext context,
) async {
  try {
    await firestore.collection('helpRequests').add(
      {
        'specialNeedId': auth_services.currentUid,
        'description': description,
        'date': selectedDate,
        'location': GeoPoint(latitude, longitude),
        'status': 'pending',
        'type': type,
      },
    );

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