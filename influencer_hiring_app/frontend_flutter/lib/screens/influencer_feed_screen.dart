import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'review_screen.dart';

class InfluencerFeedScreen extends StatefulWidget {
  @override
  State<InfluencerFeedScreen> createState() =>
      _InfluencerFeedScreenState();
}

class _InfluencerFeedScreenState
    extends State<InfluencerFeedScreen> {

  List campaigns = [];
  bool isLoading = true;

  final String baseUrl = "http://localhost:5000";

  @override
  void initState() {
    super.initState();
    fetchCampaigns();
  }

  // ===============================
  // FETCH CAMPAIGNS
  // ===============================
  Future<void> fetchCampaigns() async {

    setState(() => isLoading = true);

    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/campaign/all"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          campaigns = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("FETCH ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  // ===============================
  // APPLY TO CAMPAIGN
  // ===============================
  Future<void> applyCampaign(int campaignId) async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.post(
      Uri.parse("$baseUrl/api/campaign/apply"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "campaign_id": campaignId
      }),
    );

    if (response.statusCode == 201) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Applied successfully")),
      );

      fetchCampaigns();

    } else {

      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["error"] ?? "Error")),
      );
    }
  }

  // ===============================
  // STATUS BADGE
  // ===============================
  Widget statusBadge(String status) {

    bool isActive = status == "active";

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green
            : Colors.red,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  // ===============================
  // STAR BUILDER
  // ===============================
  Widget buildStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.round()
              ? Icons.star
              : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  // ===============================
  // APPLICATION BUTTON
  // ===============================
  Widget applicationButton(Map campaign) {

    String campaignStatus =
        campaign["status"] ?? "active";
    String? appStatus =
        campaign["application_status"];

    if (campaignStatus == "closed") {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey),
        child: Text("Campaign Closed"),
      );
    }

    if (appStatus == "pending") {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange),
        child: Text("Applied (Pending)"),
      );
    }

    if (appStatus == "accepted") {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green),
        child: Text("Accepted"),
      );
    }

    if (appStatus == "rejected") {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red),
        child: Text("Rejected"),
      );
    }

    return ElevatedButton(
      onPressed: () =>
          applyCampaign(campaign["id"]),
      child: Text("Apply Now"),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Available Campaigns"),
      ),
      body: RefreshIndicator(
        onRefresh: fetchCampaigns,
        child: isLoading
            ? Center(
                child:
                    CircularProgressIndicator())
            : campaigns.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: 250),
                      Center(
                          child: Text(
                              "No campaigns available"))
                    ],
                  )
                : ListView.builder(
                    padding:
                        EdgeInsets.all(12),
                    itemCount:
                        campaigns.length,
                    itemBuilder:
                        (context, index) {

                      final campaign =
                          campaigns[index];

                      double avg =
                          double.tryParse(
                                  campaign[
                                          "average_rating"]
                                      ?.toString() ??
                                      "0") ??
                              0;

                      int total =
                          int.tryParse(
                                  campaign[
                                          "total_reviews"]
                                      ?.toString() ??
                                      "0") ??
                              0;

                      return Card(
                        elevation: 4,
                        margin:
                            EdgeInsets.only(
                                bottom: 15),
                        child: Padding(
                          padding:
                              EdgeInsets.all(
                                  16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [

                              // Title + Status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      campaign[
                                              "title"] ??
                                          "",
                                      style:
                                          TextStyle(
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),
                                  statusBadge(
                                      campaign[
                                              "status"] ??
                                          "active")
                                ],
                              ),

                              SizedBox(
                                  height: 8),

                              Text(
                                campaign[
                                        "description"] ??
                                    "",
                                maxLines: 3,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),

                              SizedBox(
                                  height: 10),

                              // ⭐ BRAND + RATING (Clickable)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ReviewScreen(
                                        campaignId:
                                            campaign[
                                                "id"],
                                        revieweeId:
                                            campaign[
                                                "brand_id"],
                                        revieweeName:
                                            campaign[
                                                "brand_name"],
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      campaign[
                                              "brand_name"] ??
                                          "",
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w500,
                                      ),
                                    ),
                                    SizedBox(
                                        width: 8),
                                    buildStars(
                                        avg),
                                    SizedBox(
                                        width: 6),
                                    Text(avg
                                        .toStringAsFixed(
                                            1)),
                                    SizedBox(
                                        width: 4),
                                    Text(
                                        "($total)"),
                                  ],
                                ),
                              ),

                              SizedBox(
                                  height: 15),

                              SizedBox(
                                width:
                                    double.infinity,
                                child:
                                    applicationButton(
                                        campaign),
                              ),

                              SizedBox(
                                  height: 10),

                              // ✍ WRITE REVIEW BUTTON
                              SizedBox(
                                width:
                                    double.infinity,
                                child:
                                    ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ReviewScreen(
                                          campaignId:
                                              campaign[
                                                  "id"],
                                          revieweeId:
                                              campaign[
                                                  "brand_id"],
                                          revieweeName:
                                              campaign[
                                                  "brand_name"],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                      "Write Review"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}