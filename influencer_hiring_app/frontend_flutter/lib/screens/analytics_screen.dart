import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() =>
      _AnalyticsScreenState();
}

class _AnalyticsScreenState
    extends State<AnalyticsScreen> {

  final String baseUrl =
      "http://localhost:5000";

  int totalFollowers = 0;
  int totalPosts = 0;

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    int? userId = prefs.getInt("userId");

    final res = await http.get(
      Uri.parse("$baseUrl/api/profile/$userId"),
    );

    final data = jsonDecode(res.body);

    setState(() {
      totalFollowers = data["followers"];
      totalPosts = data["posts"];
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Analytics")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            Card(
              child: ListTile(
                title: Text("Total Followers"),
                trailing:
                    Text("$totalFollowers"),
              ),
            ),

            Card(
              child: ListTile(
                title: Text("Total Posts"),
                trailing:
                    Text("$totalPosts"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}