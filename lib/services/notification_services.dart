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
    "type": "service_account",
    "project_id": "awn-ju",
    "private_key_id": "7b3652d78d226274b8192a29c3c3f54885a2044e",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCniHsUB/4AFgoi\n54kfijMfADBj7tmqIXFlHGvm4+VxDgdF+J6Plb+1ZBGDcwHW3TppMDSqfGOaoOpx\nspnkn2c/0UDnhHqe0Cw+bMInlzJcXkYN32JeQ1KE6iGbWmQYPwqRw3NZ1ef7SiG2\nfpS/5YW82/ft83JyNFhtDdNhROFqoesbtEAjWhBs+9WS1vF3xplibOYHMxMm+kkz\nUQdFY/COLZMfUsXDcwcrx6oPfbI2j/i5Y4BnX1ZrBcxLI12HtQjVINphcPZZLGwP\nfUZ7LhvT/WdACJjiDj7Zl7pDlBV0SDTnRcDeYZhnz6oTQuhiLIsmul4/pKaTdpkl\nb3wSkwSFAgMBAAECggEAAQkJ4azO+Acq1t5hbY14FWf15Jg0RiXgwoQzcoDUCSfS\nCa+oozCEt8U/inVqfH5vfvjqSmdsYic+a6dz5gLKK43KfePGsjaNH3GinYYErKd0\nfV91ByoZV3Lu9DvRxIiXMyFnFBYLUfU6UhtkJe9wLSOa26CWg3gpV7svJDm9vt/w\nuMv3Mk4bmC9t+pCwBsHjDLxpKeh6jVn1XBsWOHyhfqDux5TfEf2rLFggOHx2s4aO\nN7r8H3He5Lj+BIn42zOgt/TH8wH4QDkJ8GPW1Q2kwuqJqnRkMx7qu8qHWMkDGYyA\nHVGACiZNURr4YOvV2WPr4Uo/oW3tss3H+4sjoTaDPQKBgQDai1vjeHmqL5Cvz+S9\n6t7xVayPUsDBE6z5ceSQGV4Z49Q9cROcP4XfIBGl6BJi/qlLRd8+ggmZ87oahGk8\nKOldKrTejUo2c3J2lLh01J03grKNHxENbAn5qV6ENaMwl3LPQQqJWJbVt63+mss9\ngifJG1y/Gv/6LLD1WOrSrz0oTwKBgQDEPwCBKHjMdGVa3HDhGKdN5eb1ysvJpkId\nx3Zfa/VqaZrQnWaSh+JOmHrfvMtFHI76YvQ7TaKjcGozBU+wHWIpFZASt8IVG+de\nIwwbCsTXUl4USWKWg9lhL2z0v/dJpNRYfWNx5aezQpjUoCeJOy+R3wmaSjc9Uj3f\npJ533Ju86wKBgCNSIqfA8OjwhxHjJ7UKIL4geqMvXLfX1jz6i1Y+w1ar28GSZPj7\ny0ckh7WorFATmIjx4gLYQXUATzO58sgmVJEaNeFCNJxYTEeeAbHgKwittu3X94mT\nzIjtNrlncdiIoaWdfXZ1OuuPpC9iFTb7sjJuma7JTlXAo1kD5e/nIptBAoGBALB6\nE4MSmScLWQYPjLbvy6wincLVPtO03moXMBz5YbXzB9SoZ1BIQDv7pSvEhGs/FliW\nWhlmZGZjtizxjsrKcbaOfIRImZEQCc0+6Sj8Uy1rFc1afPzrzrU1x96FLuUcBBUb\nlS0cn+V1cyhqaYNgJRQhpWoJaYmMhrWyPQt+6NJHAoGAY0ZCnejTgP98vsMhGQu1\n2NKYMgNgPB90BGyA8C0TuUQAXVgclUBTm/sJmLiW8UUD4uXf9QhdOSoa5WXP4Oy9\n10CoIIMYqO2HiA7y8bhMONPPjWBs7S520PHa52rJjzAzX/M0igG49hQ4nzraFjyE\nxvlqpImwXfODUItBzbLP1wU=\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-tvxhq@awn-ju.iam.gserviceaccount.com",
    "client_id": "115487421267142112075",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-tvxhq%40awn-ju.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
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
