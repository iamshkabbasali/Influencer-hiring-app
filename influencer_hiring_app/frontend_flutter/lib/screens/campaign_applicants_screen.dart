import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';

class CampaignApplicantsScreen extends StatefulWidget {
  final int campaignId;
  final String campaignTitle;

  const CampaignApplicantsScreen({
    Key? key,
    required this.campaignId,
    required this.campaignTitle,
  }) : super(key: key);

  @override
  State<CampaignApplicantsScreen> createState() =>
      _CampaignApplicantsScreenState();
}

class _CampaignApplicantsScreenState
    extends State<CampaignApplicantsScreen> {

  List applicants = [];
  bool isLoading = true;

  final String baseUrl = "http://localhost:5000";

  @override
  void initState() {
    super.initState();
    fetchApplicants();
  }

  // =========================
  // FETCH APPLICANTS
  // =========================
  Future<void> fetchApplicants() async {

    setState(() => isLoading = true);

    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    try {

      final response = await http.get(
        Uri.parse(
            "$baseUrl/api/campaign/applications/${widget.campaignId}"),
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {

        setState(() {
          applicants = jsonDecode(response.body);
          isLoading = false;
        });

      } else {

        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load applicants")),
        );
      }

    } catch (e) {

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server Error")),
      );
    }
  }

  // =========================
  // UPDATE STATUS
  // =========================
  Future<void> updateStatus(
      int applicationId,
      String status,
      int influencerId,
      String influencerName,
      ) async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    try {

      final response = await http.post(
        Uri.parse("$baseUrl/api/campaign/update-status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "application_id": applicationId,
          "status": status,
          "campaign_id": widget.campaignId
        }),
      );

      if (response.statusCode == 200) {

        fetchApplicants();

        // If accepted → open chat automatically
        if (status == "accepted") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                otherUserId: influencerId,
                otherUserName: influencerName,
              ),
            ),
          );
        }

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed")),
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server Error")),
      );
    }
  }

  Color statusColor(String status) {
    if (status == "accepted") return Colors.green;
    if (status == "rejected") return Colors.red;
    return Colors.orange;
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campaignTitle),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : applicants.isEmpty
              ? const Center(child: Text("No applicants yet"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: applicants.length,
                  itemBuilder: (context, index) {

                    final applicant = applicants[index];

                    final int applicationId = applicant["id"];
                    final int influencerId =
                        applicant["influencer_id"];
                    final String name = applicant["name"];
                    final String email = applicant["email"];
                    final String status =
                        applicant["status"] ?? "pending";

                    return Card(
                      elevation: 4,
                      margin:
                          const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text("Email: $email"),

                            const SizedBox(height: 8),

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor(status)
                                    .withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(
                                        20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color:
                                      statusColor(status),
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            if (status == "pending")
                              Row(
                                children: [

                                  Expanded(
                                    child:
                                        ElevatedButton(
                                      style:
                                          ElevatedButton
                                              .styleFrom(
                                        backgroundColor:
                                            Colors.green,
                                      ),
                                      onPressed: () =>
                                          updateStatus(
                                        applicationId,
                                        "accepted",
                                        influencerId,
                                        name,
                                      ),
                                      child: const Text(
                                          "Accept"),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child:
                                        ElevatedButton(
                                      style:
                                          ElevatedButton
                                              .styleFrom(
                                        backgroundColor:
                                            Colors.red,
                                      ),
                                      onPressed: () =>
                                          updateStatus(
                                        applicationId,
                                        "rejected",
                                        influencerId,
                                        name,
                                      ),
                                      child: const Text(
                                          "Reject"),
                                    ),
                                  ),
                                ],
                              )

                            else if (status ==
                                "accepted")
                              SizedBox(
                                width: double.infinity,
                                child:
                                    ElevatedButton.icon(
                                  icon: const Icon(
                                      Icons.chat),
                                  label: const Text(
                                      "Open Chat"),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ChatScreen(
                                          otherUserId:
                                              influencerId,
                                          otherUserName:
                                              name,
                                        ),
                                      ),
                                    );
                                  },
                                ),
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