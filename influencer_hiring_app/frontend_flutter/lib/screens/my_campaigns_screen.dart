import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'campaign_applicants_screen.dart';

class MyCampaignsScreen extends StatefulWidget {
  @override
  State<MyCampaignsScreen> createState() =>
      _MyCampaignsScreenState();
}

class _MyCampaignsScreenState
    extends State<MyCampaignsScreen> {

  List campaigns = [];
  bool isLoading = true;

  final String baseUrl = "http://localhost:5000";

  @override
  void initState() {
    super.initState();
    fetchMyCampaigns();
  }

  // ==============================
  // FETCH CAMPAIGNS
  // ==============================
  Future<void> fetchMyCampaigns() async {

    setState(() => isLoading = true);

    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    try {

      final response = await http.get(
        Uri.parse("$baseUrl/api/campaign/my"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("FETCH STATUS: ${response.statusCode}");
      print("FETCH BODY: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          campaigns = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load campaigns")),
        );
      }

    } catch (e) {
      print("FETCH ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  // ==============================
  // DELETE CAMPAIGN
  // ==============================
  Future<void> deleteCampaign(int id) async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    try {

      final response = await http.delete(
        Uri.parse("$baseUrl/api/campaign/delete/$id"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("DELETE STATUS: ${response.statusCode}");
      print("DELETE BODY: ${response.body}");

      if (response.statusCode == 200) {

        setState(() {
          campaigns.removeWhere((c) => c["id"] == id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Campaign deleted successfully")),
        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed")),
        );
      }

    } catch (e) {
      print("DELETE ERROR: $e");
    }
  }

  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Campaign"),
        content: Text("Are you sure you want to delete?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteCampaign(id);
            },
            child: Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================
  // UI
  // ==============================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("My Campaigns"),
      ),
      body: RefreshIndicator(
        onRefresh: fetchMyCampaigns,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : campaigns.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: 250),
                      Center(
                        child: Text(
                          "No campaigns created",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    ],
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) {

                      final campaign = campaigns[index];

                      return Card(
                        elevation: 4,
                        margin:
                            EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.all(16),
                          title: Text(
                            campaign["title"] ?? "",
                            style: TextStyle(
                                fontWeight:
                                    FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 6),
                              Text(
                                campaign["description"] ??
                                    "",
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "${campaign["applicant_count"] ?? 0} Applicants",
                                style: TextStyle(
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                confirmDelete(
                                    campaign["id"]),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CampaignApplicantsScreen(
                                  campaignId:
                                      campaign["id"],
                                  campaignTitle:
                                      campaign["title"],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}