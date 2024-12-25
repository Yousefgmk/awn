import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

var auth = FirebaseAuth.instance;
var fireStore = FirebaseFirestore.instance;

String get currentUid {
  return auth.currentUser!.uid;
}

Future<void> signIn({
  required String email,
  required String password,
  required BuildContext context,
}) async {
  try {
    UserCredential userData =
        await auth.signInWithEmailAndPassword(email: email, password: password);
  } on FirebaseAuthException catch (e) {
    _handleAuthErrors(e, context);
  }
}

Future<void> signUp({
  required String email,
  required String password,
  required BuildContext context,
  required Map<String, dynamic> data,
  required String userType,
}) async {
  try {
    final UserCredential userData = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    data['userType'] = userType;
    saveUserData(userData.user!.uid, data, userType);
  } on FirebaseAuthException catch (e) {
    _handleAuthErrors(e, context);
  }
}

void saveUserData(String id, Map<String, dynamic> data, String userType) async {
  if (userType == 'specialNeed') {
    await fireStore.collection('specialNeeds').doc(id).set(data);
  } else if (userType == 'volunteer') {
    // Initialize the rating for new volunteers
    data['rating'] = 0.0;
    data['numberOfRatings'] = 0;
    await fireStore.collection('volunteers').doc(id).set(data);
  }
}

void _handleAuthErrors(FirebaseAuthException e, BuildContext context) {
  if (e.code == 'weak-password') {
    _showSnackBar("Weak Password", context);
  } else if (e.code == 'email-already-in-use') {
    _showSnackBar("Account Exist", context);
  } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
    _showSnackBar("Wrong Password", context);
  } else if (e.code == 'user-not-found') {
    _showSnackBar("User Not Found", context);
  } else if (e.code == 'invalid-email') {
    _showSnackBar("Invalid Email", context);
  } else {
    _showSnackBar("DiffError", context);
  }
}

void _showSnackBar(String message, BuildContext context) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
    ));
  }
}

Future<void> signOut() async {
  await auth.signOut();
}

Future<DocumentSnapshot<Map<String, dynamic>>> get specialNeedData async {
  return await fireStore.collection('specialNeeds').doc(currentUid).get();
}

Future<DocumentSnapshot<Map<String, dynamic>>> get volunteerData async {
  return await fireStore.collection('volunteers').doc(currentUid).get();
}

Future<void> resetPassword({required String email}) async {
  await auth.sendPasswordResetEmail(email: email);
}

Future<void> updateDisplayName({
  required String name,
  required String userType,
}) async {
  if (userType == 'specialNeed') {
    await fireStore.collection('specialNeeds').doc(currentUid).update(
      {
        'name': name,
      },
    );
  } else if (userType == 'volunteer') {
    await fireStore.collection('volunteers').doc(currentUid).update(
      {
        'name': name,
      },
    );
  }
}

Future<void> updatePhoneNumber({
  required String phoneNumber,
  required String userType,
}) async {
  if (userType == 'specialNeed') {
    await fireStore.collection('specialNeeds').doc(currentUid).update(
      {
        'phoneNumber': phoneNumber,
      },
    );
  } else if (userType == 'volunteer') {
    await fireStore.collection('volunteers').doc(currentUid).update(
      {
        'phoneNumber': phoneNumber,
      },
    );
  }
}
