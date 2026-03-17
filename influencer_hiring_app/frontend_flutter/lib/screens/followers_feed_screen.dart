import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'post_view_screen.dart'; // NEW

class FollowersFeedScreen extends StatefulWidget {
  @override
  _FollowersFeedScreenState createState() =>
      _FollowersFeedScreenState();
}

class _FollowersFeedScreenState
    extends State<FollowersFeedScreen> {

  final String baseUrl =
      "http://localhost:5000";

  List posts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchFeed();
  }

  /// FETCH FOLLOWERS FEED
  Future<void> fetchFeed() async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String? token = prefs.getString("token");

    final res = await http.get(
      Uri.parse("$baseUrl/api/posts/feed/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {

      setState(() {
        posts = jsonDecode(res.body);
        loading = false;
      });

    }
  }

  /// LIKE POST
  Future<void> likePost(int postId, int index) async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String? token = prefs.getString("token");

    final res = await http.post(
      Uri.parse("$baseUrl/api/posts/$postId/like"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {

      setState(() {
        posts[index]["like_count"] =
            (posts[index]["like_count"] ?? 0) + 1;
      });

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Followers Feed"),
      ),

      body: loading
          ? Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? Center(
                  child: Text("No posts from followers"),
                )
              : ListView.builder(

                  itemCount: posts.length,

                  itemBuilder: (context, index) {

                    final post = posts[index];

                    return Card(
                      margin: EdgeInsets.all(10),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          /// USERNAME
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              post["name"] ?? "",
                              style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),

                          /// IMAGE
                          if (post["image"] != null)
                            Image.network(
                              "$baseUrl/${post["image"]}",
                              fit: BoxFit.cover,
                            ),

                          /// CAPTION
                          if (post["caption"] != null)
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: Text(post["caption"]),
                            ),

                          /// LIKE + COMMENT BAR
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5),

                            child: Row(
                              children: [

                                /// LIKE BUTTON
                                IconButton(
                                  icon: Icon(
                                    Icons.favorite_border,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    likePost(
                                        post["id"],
                                        index);
                                  },
                                ),

                                Text(
                                  "${post["like_count"] ?? 0}",
                                  style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold),
                                ),

                                SizedBox(width: 20),

                                /// COMMENT BUTTON
                                IconButton(
                                  icon: Icon(Icons.comment),
                                  onPressed: () {

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PostViewScreen(
                                          postId:
                                              post["id"],
                                          imageUrl:
                                              "$baseUrl/${post["image"]}",
                                          caption:
                                              post["caption"] ??
                                                  "",
                                          username:
                                              post["name"] ??
                                                  "",
                                          initialLikes:
                                              post["like_count"] ??
                                                  0,
                                        ),
                                      ),
                                    );

                                  },
                                ),

                              ],
                            ),
                          ),

                        ],
                      ),
                    );
                  },
                ),
    );
  }
}