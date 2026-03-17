import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/campaign_service.dart';
import '../main.dart';
import 'chat_screen.dart';
import 'my_applications_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  final CampaignService campaignService = CampaignService();
  List campaigns = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCampaigns();
  }

  void loadCampaigns() async {
    final data = await campaignService.fetchCampaigns();
    setState(() {
      campaigns = data;
      isLoading = false;
    });
  }

  void apply(int campaignId) async {
    bool success = await campaignService.applyToCampaign(campaignId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Applied Successfully ✅"
              : "Already Applied or Error ❌",
        ),
      ),
    );
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Campaigns"),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyApplicationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : campaigns.isEmpty
              ? Center(child: Text("No campaigns available"))
              : ListView.builder(
                  itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = campaigns[index];

                    return Card(
                      margin: EdgeInsets.all(10),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              campaign["title"] ?? "",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text("By: ${campaign["brand_name"] ?? ""}"),

                            SizedBox(height: 5),

                            Text(campaign["description"] ?? ""),

                            SizedBox(height: 10),

                            Row(
                              children: [

                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      apply(campaign["id"]);
                                    },
                                    child: Text("Apply"),
                                  ),
                                ),

                                SizedBox(width: 10),

                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            otherUserId:
                                                campaign["brand_id"],
                                            otherUserName:
                                                campaign["brand_name"],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text("Chat"),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}