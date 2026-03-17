import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {

  final String baseUrl =
      "http://localhost:5000";

  List notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String? token =
        prefs.getString("token");

    final res = await http.get(
      Uri.parse("$baseUrl/api/notifications"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      setState(() {
        notifications = jsonDecode(res.body);
      });
    }
  }

  /// ACCEPT FOLLOW REQUEST
  Future<void> acceptFollow(
      int senderId, int notificationId) async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String? token =
        prefs.getString("token");

    await http.post(
      Uri.parse("$baseUrl/api/follow/accept/$senderId"),
      headers: {"Authorization": "Bearer $token"},
    );

    await deleteNotification(notificationId);
  }

  /// REJECT FOLLOW REQUEST
  Future<void> rejectFollow(
      int senderId, int notificationId) async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String? token =
        prefs.getString("token");

    await http.delete(
      Uri.parse("$baseUrl/api/follow/$senderId"),
      headers: {"Authorization": "Bearer $token"},
    );

    await deleteNotification(notificationId);
  }

  /// DELETE NOTIFICATION
  Future<void> deleteNotification(int id) async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String? token =
        prefs.getString("token");

    await http.delete(
      Uri.parse("$baseUrl/api/notifications/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    fetchNotifications();
  }

  String buildMessage(Map n) {

    if (n["type"] == "follow") {
      return "${n["sender_name"]} started following you";
    }

    if (n["type"] == "follow_request") {
      return "${n["sender_name"]} requested to follow you";
    }

    return "New notification";
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),

      body: notifications.isEmpty
          ? Center(child: Text("No notifications"))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {

                final n = notifications[index];

                return Card(
                  margin: EdgeInsets.all(8),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        Text(buildMessage(n)),

                        if (n["type"] ==
                            "follow_request")
                          Row(
                            children: [

                              ElevatedButton(
                                onPressed: () =>
                                    acceptFollow(
                                      n["sender_id"],
                                      n["id"],
                                    ),
                                child:
                                    Text("Accept"),
                              ),

                              SizedBox(width: 10),

                              OutlinedButton(
                                onPressed: () =>
                                    rejectFollow(
                                      n["sender_id"],
                                      n["id"],
                                    ),
                                child:
                                    Text("Reject"),
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