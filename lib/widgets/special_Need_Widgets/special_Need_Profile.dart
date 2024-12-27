import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:awn/services/auth_services.dart' as auth_services;
import 'package:awn/screens/special_Need_Portal/your_requests.dart';

class SpecialNeedProfile extends StatefulWidget {
  const SpecialNeedProfile({super.key, required this.userData});
  final DocumentSnapshot userData;

  @override
  State<SpecialNeedProfile> createState() => _SpecialNeedProfileState();
}

class _SpecialNeedProfileState extends State<SpecialNeedProfile> {
  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _newPhoneNumberController =
      TextEditingController();

  void _showEditInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Info"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Update the fields you want to edit. You don't need to fill out all fields.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newNameController,
                decoration: InputDecoration(
                  labelText: "New Display Name",
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  focusedBorder: OutlineInputBorder(
                    gapPadding: 0.0,
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPhoneNumberController,
                decoration: InputDecoration(
                  labelText: "New Phone Number",
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  focusedBorder: OutlineInputBorder(
                    gapPadding: 0.0,
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _newNameController.clear();
                _newPhoneNumberController.clear();
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_newNameController.text.isNotEmpty ||
                    _newPhoneNumberController.text.isNotEmpty) {
                  if (_newNameController.text.isNotEmpty) {
                    await auth_services.updateDisplayName(
                      name: _newNameController.text.trim(),
                      userType: 'specialNeed',
                    );
                  }
                  if (_newPhoneNumberController.text.isNotEmpty) {
                    await auth_services.updatePhoneNumber(
                      phoneNumber: _newPhoneNumberController.text.trim(),
                      userType: 'specialNeed',
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Close the application and open it again"),
                    ),
                  );
                }
                _newNameController.clear();
                _newPhoneNumberController.clear();
                Navigator.of(context).pop();
              },
              child: Text(
                "Confirm",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      radius: 40,
                      child: ClipOval(
                        child: Image.asset(
                          widget.userData['gender'] == 'Male'
                              ? 'assets/images/male_avatar.webp'
                              : 'assets/images/female_avatar.png',
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.userData['name']}",
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Special need",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 60,
                top: 80,
                child: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showEditInfoDialog,
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: Card(
              elevation: 30,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.email,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "University Email",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${widget.userData['email']}",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.phone,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Phone Number",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "+962 ${widget.userData['phoneNumber']}",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.all(10),
            child: Card(
              elevation: 30,
              child: InkWell(
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => const YourRequests(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Your Requests",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "View, Edit, and Delete your requests",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
