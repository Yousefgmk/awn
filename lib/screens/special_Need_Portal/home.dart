import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import 'package:awn/screens/special_need_portal/help_form.dart';
import 'package:awn/widgets/special_need_widgets/special_need_profile.dart';
import 'package:awn/widgets/special_need_widgets/active_help_requests_list.dart';
import 'package:awn/services/auth_services.dart' as auth_services;
import 'package:awn/services/notification_services.dart' as notification_services;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  DocumentSnapshot<Map<String, dynamic>>? userData;

  void _getUserData() async {
    DocumentSnapshot<Map<String, dynamic>> data =
        await auth_services.specialNeedData;
    setState(() {
      userData = data;
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserData();
    notification_services.checkNotificationPermission(context);
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: userData != null
            ? [
                Text(
                  'Hello ${userData!['name']}\nhow can we help you today?',
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const HelpForm()));
                  },
                  label: const Text(
                    "I need help with something",
                    style: TextStyle(fontSize: 20),
                  ),
                  icon: const Icon(Symbols.person_raised_hand),
                ),
                const SizedBox(height: 30),
              ]
            : [
                const CircularProgressIndicator(),
              ],
      ),
    );

    if (_currentIndex == 1) {
      activePage = const ActiveHelpRequests();
    } else if (_currentIndex == 2) {
      activePage = SpecialNeedProfile(userData: userData!);
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
            title: const Text("Active Requests"),
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
