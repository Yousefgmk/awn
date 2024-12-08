import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awn/services/auth_services.dart' as auth_services;

class VolunteerProfile extends StatefulWidget {
  const VolunteerProfile({super.key, required this.volunteerData});
  final DocumentSnapshot volunteerData;

  @override
  State<VolunteerProfile> createState() => _VolunteerProfileState();
}

class _VolunteerProfileState extends State<VolunteerProfile> {
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
                      userType: 'volunteer',
                    );
                  }
                  if (_newPhoneNumberController.text.isNotEmpty) {
                    await auth_services.updatePhoneNumber(
                      phoneNumber: _newPhoneNumberController.text.trim(),
                      userType: 'volunteer',
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
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      radius: 40,
                      child: ClipOval(
                        child: Image.asset(
                          widget.volunteerData['gender'] == 'Male'
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
                          "${widget.volunteerData['name']}",
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Volunteer",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 5),
                        // Display the rating from the database
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('volunteers')
                              .doc(widget.volunteerData.id)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (snapshot.hasError) {
                              return const Text('Error loading rating');
                            }
                            var volunteerData = snapshot.data!.data()
                                as Map<String, dynamic>;
                            double averageRating =
                                volunteerData['rating'] ?? 0.0;

                            // Round the average rating to 2 decimal places
                            String formattedRating =
                                averageRating.toStringAsFixed(2);

                            return Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  formattedRating, // Display the formatted rating
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Major: ${widget.volunteerData['major']}",
                          style: const TextStyle(
                              fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
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
                                  "+962 ${widget.volunteerData['phoneNumber']}",
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
                          Icon(Icons.email,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Email",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${widget.volunteerData['email']}",
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
        ],
      ),
    );
  }
}