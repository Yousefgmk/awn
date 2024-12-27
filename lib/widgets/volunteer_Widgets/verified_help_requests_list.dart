import 'package:awn/widgets/volunteer_Widgets/verified_help_request.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awn/services/auth_services.dart' as auth_services;

class VerifiedHelpRequests extends StatefulWidget {
  const VerifiedHelpRequests({super.key});

  @override
  State<VerifiedHelpRequests> createState() => _VerifiedHelpRequestsState();
}

class _VerifiedHelpRequestsState extends State<VerifiedHelpRequests> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<QuerySnapshot>(
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
                    child: Column(
                      children: [
                        SizedBox(height: 340,),
                        Text(
                          "No verified help requests found",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    QueryDocumentSnapshot request = snapshot.data!.docs[index];

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: VerifiedHelpRequest(
                        request: request,
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}