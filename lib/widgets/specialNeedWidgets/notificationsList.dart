import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awn/services/auth_services.dart' as auth_services;
import 'package:awn/widgets/specialNeedWidgets/helpNotifications.dart'; 

class NotificationsList extends StatefulWidget {
  const NotificationsList({super.key});

  @override
  State<NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends State<NotificationsList> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('help_notifications') // Assuming your collection is named 'help_notifications'
                .where('userId', isEqualTo: auth_services.currentUid)
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
                      SizedBox(height: 320),
                      Text(
                        "No new notifications found", // Changed from translate("NoNotification")
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
                  QueryDocumentSnapshot notification =
                      snapshot.data!.docs[index];
                  String notificationId = notification.id;
                  Map<String, dynamic> notificationData =
                      notification.data() as Map<String, dynamic>;
                  return HelpNotification(
                    id: notificationId,
                    data: notificationData,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}