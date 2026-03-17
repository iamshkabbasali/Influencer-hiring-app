import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List chats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final response = await http.get(
        Uri.parse("http://localhost:5000/api/message/chat-list"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("CHAT LIST STATUS: ${response.statusCode}");
      print("CHAT LIST BODY: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          chats = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("CHAT LIST ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatTime(String? time) {
    if (time == null) return "";
    DateTime dt = DateTime.parse(time);
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : chats.isEmpty
              ? Center(child: Text("No chats yet"))
              : ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        child: Text(
                          chat["name"][0].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(chat["name"]),
                      subtitle: Text(
                        chat["last_message"] ?? "Image",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        formatTime(chat["created_at"]),
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              // 🔥 FIX HERE
                              otherUserId: int.parse(
                                  chat["user_id"].toString()),
                              otherUserName: chat["name"],
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