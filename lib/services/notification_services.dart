import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

FirebaseMessaging messaging = FirebaseMessaging.instance;

void checkNotificationPermission(context) async {
  NotificationSettings settings = await messaging.getNotificationSettings();

  if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
    settings = await messaging.requestPermission();
  }

  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    _showNotificationPrompt(context);
  }
}

void _showNotificationPrompt(context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Enable Notifications"),
        content: Text("Please enable notifications to stay updated."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              AppSettings.openAppSettings();
              Navigator.pop(context);
            },
            child: Text("Settings"),
          ),
        ],
      );
    },
  );
}

Future<void> saveUserToken(String userId, bool isVolunteer) async {
  String collection = isVolunteer ? "volunteers" : "specialNeeds";
  String? token = await messaging.getToken();
  if (token != null) {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(userId)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }
}

Future<void> checkUserToken(String userId, bool isVolunteer) async {
  String collection = isVolunteer ? "volunteers" : "specialNeeds";
  String? newToken = await messaging.getToken();
  if (newToken != null) {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection(collection)
        .doc(userId)
        .get();

    String? existingToken = userDoc['fcmToken'];

    if (existingToken != newToken) {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .update({'fcmToken': newToken});
    }
  }
}

Future<String> getAccessToken() async {
  var serviceAccountJson = {
    //paste here
  };
  List<String> scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
    'https://www.googleapis.com/auth/cloud-platform',
  ];

  final auth.ServiceAccountCredentials credentials =
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson);

  final auth.AccessCredentials accessCredentials =
      await auth.obtainAccessCredentialsViaServiceAccount(
    credentials,
    scopes,
    http.Client(),
  );
  return accessCredentials.accessToken.data;
}

Future<String?> getUserToken(String userId, bool isVolunteer) async {
  String collection = isVolunteer ? "volunteers" : "specialNeeds";
  DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection(collection).doc(userId).get();
  return userDoc['fcmToken'] as String?;
}

Future<void> sendNotification(
  String userId,
  bool isVolunteer,
  String title,
  String body,
) async {
  final String serverAccessTokenKey = await getAccessToken();
  const String fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/awn-ju/messages:send';
  String? token = await getUserToken(userId, isVolunteer);

  if (token != null) {
    final Map<String, dynamic> message = {
      'message': {
        'token': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'android': {
          'notification': {
            'sound': 'custom_sound',
            'channel_id': 'channel_id',
          },
        },
      },
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $serverAccessTokenKey',
    };

    final response = await http.post(
      Uri.parse(fcmEndpoint),
      headers: headers,
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print(
          'Failed to send notification: ${response.statusCode} ${response.body}');
    }
  } else {
    print('User token not found.');
  }
}
