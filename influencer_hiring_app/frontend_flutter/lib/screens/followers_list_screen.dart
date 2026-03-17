import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'profile_screen.dart';

class FollowersListScreen
    extends StatefulWidget {
  final int userId;

  const FollowersListScreen(
      {required this.userId});

  @override
  State<FollowersListScreen> createState() =>
      _FollowersListScreenState();
}

class _FollowersListScreenState
    extends State<FollowersListScreen> {

  final String baseUrl =
      "http://localhost:5000";

  List followers = [];

  @override
  void initState() {
    super.initState();
    fetchFollowers();
  }

  Future<void> fetchFollowers() async {
    final res = await http.get(
      Uri.parse(
          "$baseUrl/api/follow/followers/${widget.userId}"),
    );

    if (res.statusCode == 200) {
      setState(() {
        followers = jsonDecode(res.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar:
          AppBar(title: Text("Followers")),
      body: ListView.builder(
        itemCount: followers.length,
        itemBuilder:
            (context, index) {

          final follower =
              followers[index];

          return ListTile(
            title: Text(follower["name"]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProfileScreen(
                          userId:
                              follower["id"]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}