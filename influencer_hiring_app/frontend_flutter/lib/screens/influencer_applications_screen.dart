import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'review_screen.dart';

class InfluencerApplicationsScreen extends StatefulWidget {
  @override
  _InfluencerApplicationsScreenState createState() =>
      _InfluencerApplicationsScreenState();
}

class _InfluencerApplicationsScreenState
    extends State<InfluencerApplicationsScreen> {

  List applications = [];
  bool isLoading = true;

  final String baseUrl = "http://localhost:5000";

  @override
  void initState() {
    super.initState();
    fetchApplications();
  }

  // ===============================
  // FETCH MY APPLICATIONS
  // ===============================
  Future<void> fetchApplications() async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    try {

      final response = await http.get(
        Uri.parse("$baseUrl/api/campaign/my-applications"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          applications = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }

    } catch (e) {
      print("APPLICATION FETCH ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  // ===============================
  // STATUS COLOR
  // ===============================
  Color statusColor(String status) {
    if (status == "accepted") return Colors.green;
    if (status == "rejected") return Colors.red;
    return Colors.orange;
  }

  // ===============================
  // SAFE INT PARSER
  // ===============================
  int safeInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("My Applications"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : applications.isEmpty
              ? Center(child: Text("No applications yet"))
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: applications.length,
                  itemBuilder: (context, index) {

                    final app = applications[index];
                    final status =
                        app["status"] ?? "pending";

                    // SAFE VALUES
                    int campaignId =
                        safeInt(app["campaign_id"] ?? app["id"]);
                    int brandId =
                        safeInt(app["brand_id"]);
                    String brandName =
                        app["brand_name"] ?? "User";

                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            // Campaign Title
                            Text(
                              app["title"] ?? "",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 6),

                            // Brand Name
                            Text(
                              "Brand: $brandName",
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),

                            SizedBox(height: 10),

                            // Status Badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor(status)
                                    .withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(20),
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

                            SizedBox(height: 15),

                            // ⭐ WRITE REVIEW BUTTON
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.star),
                                label: Text("Write Review"),
                                style:
                                    ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.amber,
                                ),
                                onPressed: () {

                                  if (campaignId == 0 ||
                                      brandId == 0) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "Invalid review data"),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ReviewScreen(
                                        campaignId:
                                            campaignId,
                                        revieweeId:
                                            brandId,
                                        revieweeName:
                                            brandName,
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