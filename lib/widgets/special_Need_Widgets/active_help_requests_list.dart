import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:awn/widgets/special_need_widgets/active_help_request.dart';
import 'package:awn/services/auth_services.dart' as auth_services;

class ActiveHelpRequests extends StatefulWidget {
  const ActiveHelpRequests({super.key});

  @override
  State<ActiveHelpRequests> createState() => _ActiveHelpRequestsState();
}

class _ActiveHelpRequestsState extends State<ActiveHelpRequests> {

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('helpRequests')
          .where('specialNeedId', isEqualTo: auth_services.currentUid)
          .where('status', whereIn: ['accepted', 'verified']).snapshots(),
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
              "No accepted or verified help requests found",
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
            return ActiveHelpRequest(request: request);
          },
        );
      },
    );
  }
}
