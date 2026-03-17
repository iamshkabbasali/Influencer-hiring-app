import 'dart:convert';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'search_screen.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import 'create_campaign_screen.dart';
import 'my_campaigns_screen.dart';
import 'chat_list_screen.dart';
import 'review_screen.dart';
import 'influencer_feed_screen.dart';
import 'followers_feed_screen.dart'; // NEW IMPORT

class BrandDashboardScreen extends StatefulWidget {
  @override
  State<BrandDashboardScreen> createState() =>
      _BrandDashboardScreenState();
}

class _BrandDashboardScreenState
    extends State<BrandDashboardScreen> {

  final String baseUrl =
      "http://localhost:5000";

  double averageRating = 0;
  int totalReviews = 0;
  bool isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    fetchMyRating();
  }

  Future<void> fetchMyRating() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$baseUrl/api/campaign/rating/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        averageRating = double.tryParse(
                data["average_rating"]?.toString() ?? "0") ??
            0;
        totalReviews = data["total_reviews"] ?? 0;
        isLoadingRating = false;
      });
    } else {
      setState(() => isLoadingRating = false);
    }
  }

  Future<int> getUnreadCount() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final res = await http.get(
      Uri.parse("$baseUrl/api/notifications"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      List data = jsonDecode(res.body);
      return data.where((n) => n["is_read"] == 0).length;
    }

    return 0;
  }

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  Widget buildStars(double rating) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.round()
              ? Icons.star
              : Icons.star_border,
          color: Colors.amber,
        );
      }),
    );
  }

  Widget buildDashboardButton(
      IconData icon, String text, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
              vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon),
        label: Text(text),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Brand Dashboard"),

        actions: [

          /// HOME BUTTON → FOLLOWERS FEED
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FollowersFeedScreen(),
                ),
              );
            },
          ),

          /// SEARCH
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SearchScreen(),
                ),
              );
            },
          ),

          /// NOTIFICATIONS
          FutureBuilder<int>(
            future: getUnreadCount(),
            builder: (context, snapshot) {
              int count = snapshot.data ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon:
                        Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              NotificationScreen(),
                        ),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                  ),

                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding:
                            EdgeInsets.all(4),
                        decoration:
                            BoxDecoration(
                          color: Colors.red,
                          shape:
                              BoxShape.circle,
                        ),
                        child: Text(
                          count.toString(),
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          /// PROFILE
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () async {
              SharedPreferences prefs =
                  await SharedPreferences
                      .getInstance();
              int? userId =
                  prefs.getInt("userId");

              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileScreen(
                            userId: userId),
                  ),
                );
              }
            },
          ),

          /// CHAT
          IconButton(
            icon: Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatListScreen(),
                ),
              );
            },
          ),

          /// LOGOUT
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () =>
                logout(context),
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [

            SizedBox(height: 20),

            Card(
              elevation: 3,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    EdgeInsets.all(16),
                child: Column(
                  children: [

                    Text(
                      "Your Rating",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10),

                    isLoadingRating
                        ? CircularProgressIndicator()
                        : Column(
                            children: [
                              buildStars(
                                  averageRating),
                              SizedBox(
                                  height: 6),
                              Text(
                                averageRating
                                    .toStringAsFixed(
                                        1),
                                style:
                                    TextStyle(
                                  fontSize:
                                      18,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              Text(
                                "$totalReviews Reviews",
                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            /// INFLUENCER FEED
            buildDashboardButton(
                Icons.dynamic_feed,
                "Influencer Feed", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      InfluencerFeedScreen(),
                ),
              );
            }),

            /// CREATE CAMPAIGN
            buildDashboardButton(
                Icons.add,
                "Create Campaign", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateCampaignScreen(),
                ),
              );
            }),

            /// MY CAMPAIGNS
            buildDashboardButton(
                Icons.folder,
                "My Campaigns", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MyCampaignsScreen(),
                ),
              );
            }),

            /// REVIEWS
            buildDashboardButton(
                Icons.star,
                "View My Reviews", () async {
              SharedPreferences prefs =
                  await SharedPreferences
                      .getInstance();
              int? userId =
                  prefs.getInt("userId");

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ReviewScreen(
                    campaignId: 0,
                    revieweeId:
                        userId ?? 0,
                    revieweeName:
                        "My Reviews",
                  ),
                ),
              );
            }),

            Spacer(),

            Center(
              child: Text(
                "Welcome Brand 👋\nManage your campaigns easily.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}