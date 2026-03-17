import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PostViewScreen extends StatefulWidget {

  final int postId;
  final String imageUrl;
  final String caption;
  final String username;
  final int initialLikes;

  const PostViewScreen({
    required this.postId,
    required this.imageUrl,
    required this.caption,
    required this.username,
    required this.initialLikes,
  });

  @override
  State<PostViewScreen> createState() =>
      _PostViewScreenState();
}

class _PostViewScreenState
    extends State<PostViewScreen> {

  final String baseUrl =
      "http://localhost:5000";

  late int likeCount;
  bool isLiked = false;

  List comments = [];

  bool isLoadingComments = true;

  final TextEditingController commentController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    likeCount = widget.initialLikes;
    fetchInitialState();
  }

  /// FETCH CURRENT LIKE STATE + COMMENTS
  Future<void> fetchInitialState() async {
    await fetchLikeState();
    await fetchComments();
  }

  /// FETCH LIKE STATE FROM SERVER
  Future<void> fetchLikeState() async {

    try {

      SharedPreferences prefs =
          await SharedPreferences.getInstance();

      String? token = prefs.getString("token");

      final res = await http.get(
        Uri.parse(
            "$baseUrl/api/posts/${widget.postId}/like-status"),
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      if (res.statusCode == 200) {

        final data = jsonDecode(res.body);

        setState(() {
          isLiked = data["is_liked"] ?? false;
          likeCount = data["like_count"] ??
              widget.initialLikes;
        });
      }

    } catch (e) {
      print("LIKE STATE ERROR: $e");
    }
  }

  /// TOGGLE LIKE
  Future<void> toggleLike() async {

    try {

      SharedPreferences prefs =
          await SharedPreferences.getInstance();

      String? token = prefs.getString("token");

      final res = await http.post(
        Uri.parse(
            "$baseUrl/api/posts/like/${widget.postId}"),
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      if (res.statusCode == 200) {

        final data = jsonDecode(res.body);

        setState(() {
          isLiked = data["liked"];
          likeCount = data["like_count"];
        });

      }

    } catch (e) {
      print("LIKE ERROR: $e");
    }
  }

  /// FETCH COMMENTS
  Future<void> fetchComments() async {

    try {

      setState(() {
        isLoadingComments = true;
      });

      final res = await http.get(
        Uri.parse(
            "$baseUrl/api/posts/comments/${widget.postId}"),
      );

      if (res.statusCode == 200) {

        setState(() {
          comments = jsonDecode(res.body);
        });
      }

    } catch (e) {
      print("COMMENTS ERROR: $e");
    }

    setState(() {
      isLoadingComments = false;
    });
  }

  /// ADD COMMENT
  Future<void> addComment() async {

    if (commentController.text.trim().isEmpty) {
      return;
    }

    try {

      SharedPreferences prefs =
          await SharedPreferences.getInstance();

      String? token = prefs.getString("token");

      final res = await http.post(
        Uri.parse(
            "$baseUrl/api/posts/comment/${widget.postId}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "text":
              commentController.text.trim()
        }),
      );

      if (res.statusCode == 200 ||
          res.statusCode == 201) {

        final newComment = jsonDecode(res.body);

        setState(() {
          comments.insert(0, newComment);
        });

        commentController.clear();
      }

    } catch (e) {
      print("ADD COMMENT ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.username),
      ),

      body: Column(
        children: [

          /// POST IMAGE
          GestureDetector(
            onDoubleTap: toggleLike,
            child: Image.network(
              widget.imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),

          /// LIKE BUTTON
          Row(
            children: [

              IconButton(
                icon: Icon(
                  isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: isLiked
                      ? Colors.red
                      : Colors.black,
                ),
                onPressed: toggleLike,
              ),

              Text("$likeCount likes"),

            ],
          ),

          /// CAPTION
          Padding(
            padding:
                EdgeInsets.symmetric(
                    horizontal: 12),
            child: Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                "${widget.username} ${widget.caption}",
                style: TextStyle(
                    fontWeight:
                        FontWeight.w500),
              ),
            ),
          ),

          Divider(),

          /// COMMENTS
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchComments,
              child: isLoadingComments
                  ? Center(
                      child:
                          CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: comments.length,
                      itemBuilder:
                          (context, index) {

                        final comment =
                            comments[index];

                        return ListTile(
                          leading: CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                              comment["name"] ?? ""),
                          subtitle: Text(
                              comment["text"] ?? ""),
                        );
                      },
                    ),
            ),
          ),

          /// ADD COMMENT
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller:
                        commentController,
                    decoration:
                        InputDecoration(
                      hintText:
                          "Add a comment...",
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                ),

                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: addComment,
                )

              ],
            ),
          )

        ],
      ),
    );
  }
}