import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:awn/widgets/custom_dropdown_button.dart';
import 'package:awn/widgets/volunteer_widgets/help_request.dart';
import 'package:awn/services/auth_services.dart' as auth_services;

class HelpRequestsList extends StatefulWidget {
  const HelpRequestsList({super.key});

  @override
  State<HelpRequestsList> createState() => _HelpRequestsListState();
}

class _HelpRequestsListState extends State<HelpRequestsList> {
  String? _selectedTypeFilter;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CustomDropdownButton(
                  controller: TextEditingController(),
                  selectedDropDownValue: _selectedTypeFilter,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTypeFilter = newValue;
                    });
                  },
                  isFilter: true,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTypeFilter = null;
                    });
                  },
                  child: Text(
                    "Reset",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('helpRequests')
                  .where('volunteerId2', isEqualTo: "")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      children: [
                        SizedBox(height: 270),
                        Text(
                          "No help requests found.",
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

                return FutureBuilder<DocumentSnapshot>(
                  future: auth_services.volunteerData,
                  builder: (context, volunteerSnapshot) {
                    if (volunteerSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (volunteerSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${volunteerSnapshot.error}'));
                    }

                    if (!volunteerSnapshot.hasData) {
                      return const Center(
                        child: Text(
                          "Volunteer data not found.",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }

                    String volunteerId1 = volunteerSnapshot.data!.id;
                    String volunteerMajor = volunteerSnapshot.data!['major'];

                    List<QueryDocumentSnapshot> allRequests =
                        snapshot.data!.docs;

                    // Filter requests based on additional conditions
                    List<QueryDocumentSnapshot> filteredRequests =
                        allRequests.where((request) {
                      Map<String, dynamic> requestData =
                          request.data() as Map<String, dynamic>;
                      List<dynamic> rejectedIds =
                          requestData['rejectedIds'] ?? [];
                      DateTime requestTime = requestData['date'].toDate();

                      if(requestTime.isBefore(DateTime.now())) {
                        return false;
                      }
                      else if (rejectedIds.contains(volunteerId1)) {
                        return false;
                      } else if (requestData['requestedMajor'] != null &&
                          requestData['requestedMajor'] != volunteerMajor) {
                        return false;
                      } else if ((requestData['status'] == 'Accepted' ||
                              requestData['status'] == 'Assigned') &&
                          requestData['volunteerId1'] ==
                              auth_services.currentUid) {
                        return false;
                      } else if (_selectedTypeFilter != null &&
                          requestData['type'] != _selectedTypeFilter) {
                        return false;
                      }

                      return true;
                    }).toList();

                    return filteredRequests.isEmpty
                        ? Center(
                            child: Column(
                              children: [
                                SizedBox(height: 270),
                                Text(
                                  "No help requests found",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredRequests.length,
                            itemBuilder: (context, index) {
                              QueryDocumentSnapshot request = filteredRequests[index];

                              return Container(
                                margin: EdgeInsets.symmetric(vertical: 6),
                                child: HelpRequest(
                                  request: request,
                                ),
                              );
                            },
                          );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
