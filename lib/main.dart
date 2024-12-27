import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:awn/firebase_options.dart';
import 'package:awn/screens/login_screen.dart';
import 'package:awn/screens/volunteer_Portal/home.dart' as volunteer;
import 'package:awn/screens/special_Need_Portal/home.dart' as special_need;
import 'package:awn/services/auth_services.dart' as auth_services;
import 'package:awn/theme.dart' as custom_theme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String?> _getUserType(String uid) async {
    DocumentSnapshot specialNeedsDoc = await FirebaseFirestore.instance
        .collection('specialNeeds')
        .doc(uid)
        .get();
    DocumentSnapshot volunteerDoc = await FirebaseFirestore.instance
        .collection('volunteers')
        .doc(uid)
        .get();

    if (specialNeedsDoc.exists) {
      return 'specialNeed';
    }
    if (volunteerDoc.exists) {
      return 'volunteer';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AWN",
      theme: custom_theme.theme,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: auth_services.auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            String uid = snapshot.data!.uid;
            return FutureBuilder<String?>(
              future: _getUserType(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    color: Colors.white,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Container(
                    color: Colors.white,
                    child: const Center(
                        child: Text(
                      'Error loading user data',
                      style: TextStyle(color: Colors.black),
                    )),
                  );
                } else if (snapshot.hasData) {
                  String? userType = snapshot.data;
                  if (userType == 'specialNeed') {
                    return const special_need.Home();
                  }
                  if (userType == 'volunteer') {
                    return const volunteer.Home();
                  }
                }
                return Container(
                  color: Colors.white,
                  child: const Center(
                      child: Text('User data not found',
                          style: TextStyle(color: Colors.black))),
                );
              },
            );
          }
          return const AuthenticationPage();
        },
      ),
    );
  }
}
