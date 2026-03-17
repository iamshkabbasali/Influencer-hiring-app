import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'view_applicants_screen.dart';

class BrandCampaignsScreen extends StatefulWidget {
  @override
  _BrandCampaignsScreenState createState() =>
      _BrandCampaignsScreenState();
}

class _BrandCampaignsScreenState
    extends State<BrandCampaignsScreen> {

  List campaigns = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCampaigns();
  }

  Future<void> fetchCampaigns() async {
    try {
      SharedPreferences prefs =
          await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final url =
          Uri.parse("http://localhost:5000/api/campaign/my");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      print("MY CAMPAIGNS STATUS: ${response.statusCode}");
      print("MY CAMPAIGNS BODY: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          campaigns = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("CAMPAIGN FETCH ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("My Campaigns")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : campaigns.isEmpty
              ? Center(child: Text("No Campaigns Created"))
              : ListView.builder(
                  itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = campaigns[index];

                    return Card(
                      margin: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: ListTile(
                        title: Text(
                          campaign["title"],
                          style: TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle:
                            Text(campaign["description"]),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ViewApplicantsScreen(
                                campaignId: campaign["id"],
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
    );
  }
}