import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ViewApplicantsScreen extends StatefulWidget {
  final int campaignId;
  final String campaignTitle;

  const ViewApplicantsScreen({
    Key? key,
    required this.campaignId,
    required this.campaignTitle,
  }) : super(key: key);

  @override
  _ViewApplicantsScreenState createState() =>
      _ViewApplicantsScreenState();
}

class _ViewApplicantsScreenState
    extends State<ViewApplicantsScreen> {

  List applicants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApplicants();
  }

  Future<void> fetchApplicants() async {
    try {
      SharedPreferences prefs =
          await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final url = Uri.parse(
          "http://localhost:5000/api/campaign/applicants/${widget.campaignId}");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      print("APPLICANTS STATUS: ${response.statusCode}");
      print("APPLICANTS BODY: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          applicants = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load applicants")),
        );
      }
    } catch (e) {
      print("FETCH ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> updateStatus(
      int applicationId, String status) async {

    try {
      SharedPreferences prefs =
          await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final url = Uri.parse(
          "http://localhost:5000/api/campaign/application/$applicationId");

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({"status": status}),
      );

      if (response.statusCode == 200) {
        fetchApplicants();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Update failed")),
        );
      }
    } catch (e) {
      print("UPDATE ERROR: $e");
    }
  }

  Color statusColor(String status) {
    if (status == "accepted") return Colors.green;
    if (status == "rejected") return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campaignTitle),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : applicants.isEmpty
              ? const Center(child: Text("No Applicants Yet"))
              : ListView.builder(
                  itemCount: applicants.length,
                  itemBuilder: (context, index) {
                    final applicant = applicants[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          crossAxisAlignment:
                              CrossAxisAlignment.center,
                          children: [

                            // LEFT SIDE
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    applicant["name"],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    applicant["email"],
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // RIGHT SIDE
                            Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [

                                Text(
                                  applicant["status"],
                                  style: TextStyle(
                                    color: statusColor(
                                        applicant["status"]),
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Row(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.check,
                                          color:
                                              Colors.green),
                                      onPressed: () {
                                        updateStatus(
                                            applicant[
                                                "application_id"],
                                            "accepted");
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.close,
                                          color: Colors.red),
                                      onPressed: () {
                                        updateStatus(
                                            applicant[
                                                "application_id"],
                                            "rejected");
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}