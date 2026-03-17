import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() =>
      _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  final String baseUrl = "http://localhost:5000";
  final searchController = TextEditingController();
  List users = [];

  Future<void> searchUsers(String keyword) async {
    if (keyword.isEmpty) return;

    final res = await http.get(
      Uri.parse("$baseUrl/api/search?q=$keyword"),
    );

    setState(() {
      users = jsonDecode(res.body);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: "Search users...",
            border: InputBorder.none,
          ),
          onChanged: searchUsers,
        ),
      ),

      body: users.isEmpty
          ? Center(child: Text("Search for users"))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(user["name"]),
                  subtitle: Text(user["bio"] ?? ""),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfileScreen(
                                userId: user["id"]),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}