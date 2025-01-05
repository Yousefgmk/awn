import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import 'package:awn/widgets/volunteer_widgets/volunteer_profile.dart';
import 'package:awn/widgets/volunteer_widgets/help_requests_list.dart';
import 'package:awn/widgets/volunteer_widgets/assigned_help_requests_list.dart';
import 'package:awn/services/auth_services.dart' as auth_services;
import 'package:awn/services/notification_services.dart' as notification_services;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  DocumentSnapshot<Map<String, dynamic>>? volunteerData;

  void _getVolunteerData() async {
    DocumentSnapshot<Map<String, dynamic>> data =
        await auth_services.volunteerData;
    setState(() {
      volunteerData = data;
    });
  }

  @override
  void initState() {
    super.initState();
    _getVolunteerData();
    notification_services.checkNotificationPermission(context);
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage = const HelpRequestsList();

    if (_currentIndex == 1) {
      activePage = const AssignedHelpRequests();
    } else if (_currentIndex == 2) {
      activePage = VolunteerProfile(volunteerData: volunteerData!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AWN",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: const Text(
                      "Are you sure you want to sign out?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await auth_services.signOut();
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: activePage,
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home),
            title: const Text("Home"),
            selectedColor: Theme.of(context).colorScheme.primary,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.library_add_check_outlined),
            title: const Text("Assigned Requests"),
            selectedColor: Theme.of(context).colorScheme.primary,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.person),
            title: const Text("Profile"),
            selectedColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
