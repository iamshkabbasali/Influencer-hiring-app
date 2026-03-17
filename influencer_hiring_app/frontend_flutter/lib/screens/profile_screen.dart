import 'dart:convert';
import 'dart:io';

import 'portfolio_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'chat_screen.dart';
import 'followers_list_screen.dart';
import 'following_list_screen.dart';
import 'create_post_screen.dart';
import 'upload_portfolio_screen.dart';
import 'post_view_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final String baseUrl =
      "http://localhost:5000";

  Map user = {};
  List posts = [];
  List portfolio = [];

  String followStatus = "none";
  bool isPrivateBlocked = false;
  bool isLoading = true;

  int followers = 0;
  int following = 0;
  int postCount = 0;

  int? myUserId;
  String? token;

  bool get isMyProfile =>
      myUserId == widget.userId;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    try {

      SharedPreferences prefs =
          await SharedPreferences.getInstance();

      token = prefs.getString("token");
      myUserId = prefs.getInt("userId");

      await Future.wait([
        fetchProfile(),
        fetchFollowStatus(),
        fetchPosts(),
        fetchPortfolio(),
      ]);

    } catch (e) {
      print("INIT ERROR: $e");
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// PROFILE

  Future<void> fetchProfile() async {

    final res = await http.get(
      Uri.parse(
          "$baseUrl/api/profile/${widget.userId}"),
    );

    if (res.statusCode != 200) return;

    final data = jsonDecode(res.body);

    setState(() {
      user = data["user"];
      followers = data["followers"];
      following = data["following"];
      postCount = data["posts"];
    });
  }

  /// EDIT BIO

  Future<void> editBio() async {

    TextEditingController controller =
        TextEditingController(text: user["bio"] ?? "");

    showDialog(
      context: context,
      builder: (_) {

        return AlertDialog(
          title: Text("Edit Bio"),
          content: TextField(
            controller: controller,
            maxLines: 3,
          ),
          actions: [

            TextButton(
              child: Text("Cancel"),
              onPressed: () =>
                  Navigator.pop(context),
            ),

            ElevatedButton(
              child: Text("Save"),
              onPressed: () async {

                await http.put(
                  Uri.parse(
                      "$baseUrl/api/profile/update"),
                  headers: {
                    "Content-Type":
                        "application/json",
                    "Authorization":
                        "Bearer $token"
                  },
                  body: jsonEncode({
                    "bio": controller.text
                  }),
                );

                Navigator.pop(context);
                fetchProfile();
              },
            )

          ],
        );
      },
    );
  }

  /// PROFILE PICTURE

  Future<void> uploadAvatar() async {

    final picker = ImagePicker();

    final file = await picker.pickImage(
        source: ImageSource.gallery);

    if (file == null) return;

    var request = http.MultipartRequest(
      "POST",
      Uri.parse(
          "$baseUrl/api/profile/upload-avatar"),
    );

    request.headers["Authorization"] =
        "Bearer $token";

    request.files.add(
      await http.MultipartFile.fromPath(
          "avatar", file.path),
    );

    await request.send();

    fetchProfile();
  }

  Future<void> removeAvatar() async {

    await http.delete(
      Uri.parse(
          "$baseUrl/api/profile/remove-avatar"),
      headers: {"Authorization": "Bearer $token"},
    );

    fetchProfile();
  }

  /// FOLLOW SYSTEM

  Future<void> fetchFollowStatus() async {

    if (myUserId == widget.userId) return;
    if (token == null) return;

    final res = await http.get(
      Uri.parse(
          "$baseUrl/api/follow/status/${widget.userId}"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) return;

    final data = jsonDecode(res.body);

    setState(() {
      followStatus = data["status"];
    });
  }

  Future<void> followUser() async {

    await http.post(
      Uri.parse(
          "$baseUrl/api/follow/${widget.userId}"),
      headers: {"Authorization": "Bearer $token"},
    );

    await fetchFollowStatus();
    await fetchProfile();
  }

  Future<void> unfollowUser() async {

    await http.delete(
      Uri.parse(
          "$baseUrl/api/follow/${widget.userId}"),
      headers: {"Authorization": "Bearer $token"},
    );

    await fetchFollowStatus();
    await fetchProfile();
  }

  /// POSTS

  Future<void> fetchPosts() async {

    if (token == null) return;

    final res = await http.get(
      Uri.parse(
          "$baseUrl/api/posts/user/${widget.userId}"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 403) {
      setState(() {
        isPrivateBlocked = true;
      });
      return;
    }

    if (res.statusCode != 200) return;

    final data = jsonDecode(res.body);

    setState(() {
      posts = data;
      postCount = posts.length;
      isPrivateBlocked = false;
    });
  }

  /// PORTFOLIO

  Future<void> fetchPortfolio() async {

    final res = await http.get(
      Uri.parse(
          "$baseUrl/api/portfolio/${widget.userId}"),
    );

    if (res.statusCode != 200) return;

    final data = jsonDecode(res.body);

    setState(() {
      portfolio = data;
    });
  }

  Future<void> deletePortfolio(int id) async {

    await http.delete(
      Uri.parse("$baseUrl/api/portfolio/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    fetchPortfolio();
  }

  /// FOLLOW BUTTON

  Widget buildFollowButton() {

    if (followStatus == "accepted") {
      return ElevatedButton(
        onPressed: unfollowUser,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey),
        child: Text("Following"),
      );
    }

    if (followStatus == "pending") {
      return ElevatedButton(
        onPressed: null,
        child: Text("Requested"),
      );
    }

    return ElevatedButton(
      onPressed: followUser,
      child: Text("Follow"),
    );
  }

  /// MESSAGE BUTTON

  Widget buildMessageButton() {

    return ElevatedButton.icon(
      icon: Icon(Icons.chat_bubble_outline),
      label: Text("Message"),
      onPressed: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              otherUserId: widget.userId,
              otherUserName: user["name"] ?? "User",
            ),
          ),
        );

      },
    );
  }

  Widget buildStat(String label, int count) {

    return InkWell(
      onTap: () {

        if (label == "Followers") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FollowersListScreen(
                      userId: widget.userId),
            ),
          );
        }

        if (label == "Following") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FollowingListScreen(
                      userId: widget.userId),
            ),
          );
        }
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }

  /// UI

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user["name"] ?? "Profile"),
      ),
      body: RefreshIndicator(
        onRefresh: initData,
        child: SingleChildScrollView(
          physics:
              AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [

              SizedBox(height: 20),

              GestureDetector(
                onTap: isMyProfile
                    ? uploadAvatar
                    : null,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      user["profile_picture"] != null
                          ? NetworkImage(
                              "$baseUrl/${user["profile_picture"]}")
                          : null,
                  child:
                      user["profile_picture"] == null
                          ? Icon(Icons.person,
                              size: 40)
                          : null,
                ),
              ),

              if (isMyProfile)
                TextButton(
                    onPressed: removeAvatar,
                    child: Text("Remove Photo")),

              SizedBox(height: 10),

              Text(
                user["name"] ?? "",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold),
              ),

              SizedBox(height: 5),

              Text(user["bio"] ?? "No bio"),

              if (isMyProfile)
                TextButton(
                    onPressed: editBio,
                    child: Text("Edit Bio")),

              SizedBox(height: 10),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  buildStat("Posts", postCount),
                  buildStat("Followers", followers),
                  buildStat("Following", following),
                ],
              ),

              SizedBox(height: 10),

              if (!isMyProfile)
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    buildFollowButton(),
                    SizedBox(width: 10),
                    buildMessageButton(),
                  ],
                ),

              if (isMyProfile) ...[

                SizedBox(height: 15),

                ElevatedButton.icon(
                  icon: Icon(Icons.add_a_photo),
                  label: Text("Upload Post"),
                  onPressed: () async {

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreatePostScreen(),
                      ),
                    );

                    await fetchPosts();
                  },
                ),

                SizedBox(height: 10),

                ElevatedButton.icon(
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text("Upload Portfolio"),
                  onPressed: () async {

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UploadPortfolioScreen(),
                      ),
                    );

                    await fetchPortfolio();
                  },
                ),

              ],

              SizedBox(height: 20),
              Divider(),

              Padding(
                padding:
                    const EdgeInsets.all(8.0),
                child: Text(
                  "Portfolio",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold),
                ),
              ),

              portfolio.isEmpty
                  ? Text("No portfolio added")
                  : Column(
                      children:
                          portfolio.map((p) {

                        return GestureDetector(
                          onTap: () {

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PortfolioViewScreen(
                                  imageUrl:
                                      "$baseUrl/${p["file_url"]}",
                                  title:
                                      p["title"] ?? "",
                                  description:
                                      p["description"] ??
                                          "",
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [

                                if (p["file_url"] != null)
                                  Image.network(
                                    "$baseUrl/${p["file_url"]}",
                                    width:
                                        double.infinity,
                                    height: 300,
                                    fit: BoxFit.cover,
                                  ),

                                Padding(
                                  padding:
                                      EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [

                                      Text(
                                        p["title"] ??
                                            "",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),

                                      if (p["description"] !=
                                          null)
                                        Padding(
                                          padding:
                                              EdgeInsets
                                                  .only(
                                                      top:
                                                          4),
                                          child: Text(
                                            p["description"],
                                            style: TextStyle(
                                                color:
                                                    Colors.grey),
                                          ),
                                        ),

                                      if (isMyProfile)
                                        Align(
                                          alignment:
                                              Alignment
                                                  .centerRight,
                                          child: IconButton(
                                            icon: Icon(
                                                Icons
                                                    .delete,
                                                color: Colors
                                                    .red),
                                            onPressed: () =>
                                                deletePortfolio(
                                                    p["id"]),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

              Divider(),

              GridView.builder(
                shrinkWrap: true,
                physics:
                    NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemBuilder:
                    (context, index) {

                  final post = posts[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PostViewScreen(
                            postId: post["id"],
                            imageUrl:
                                "$baseUrl/${post["image"]}",
                            caption:
                                post["caption"] ??
                                    "",
                            username:
                                user["name"] ?? "",
                            initialLikes:
                                post["like_count"] ??
                                    0,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.all(2),
                      color: Colors.grey[300],
                      child: post["image"] != null
                          ? Image.network(
                              "$baseUrl/${post["image"]}",
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.image),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}