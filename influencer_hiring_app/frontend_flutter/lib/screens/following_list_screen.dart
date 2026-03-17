import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'profile_screen.dart';

class FollowingListScreen extends StatefulWidget {
  final int userId;

  const FollowingListScreen({required this.userId});

  @override
  _FollowingListScreenState createState() =>
      _FollowingListScreenState();
}

class _FollowingListScreenState
    extends State<FollowingListScreen> {

  final String baseUrl =
      "http://localhost:5000";

  List following = [];

  @override
  void initState() {
    super.initState();
    fetchFollowing();
  }

  Future<void> fetchFollowing() async {

    final res = await http.get(
      Uri.parse(
          "$baseUrl/api/follow/following/${widget.userId}"),
    );

    setState(() {
      following = jsonDecode(res.body);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Following")),
      body: following.isEmpty
          ? Center(child: Text("Not following anyone"))
          : ListView.builder(
              itemCount: following.length,
              itemBuilder: (context, index) {

                final user = following[index];

                return ListTile(
                  leading:
                      CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user["name"]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfileScreen(
                          userId: user["id"],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}