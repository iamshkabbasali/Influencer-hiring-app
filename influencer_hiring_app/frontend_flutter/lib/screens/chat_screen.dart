import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;

  ChatScreen({
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  List messages = [];
  List filteredMessages = [];

  Timer? _timer;
  bool isLoading = true;

  final messageController = TextEditingController();
  final picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchMessages();

    _timer = Timer.periodic(
      Duration(seconds: 3),
      (_) => fetchMessages(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchMessages() async {

    try {

      SharedPreferences prefs =
          await SharedPreferences.getInstance();

      String? token = prefs.getString("token");

      final url = Uri.parse(
          "http://localhost:5000/api/message/conversation/${widget.otherUserId}");

      final response =
          await http.get(url, headers: {"Authorization": "Bearer $token"});

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        setState(() {
          messages = data;
          filteredMessages = data;
          isLoading = false;
        });

        Future.delayed(Duration(milliseconds: 100), () {
          scrollToBottom();
        });

      } else {

        setState(() {
          isLoading = false;
        });

      }

    } catch (e) {

      print("CHAT FETCH ERROR: $e");

      setState(() {
        isLoading = false;
      });

    }

  }

  void scrollToBottom() {

    if (_scrollController.hasClients) {

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

    }

  }

  /// SEARCH MESSAGES
  void openSearch() {

    TextEditingController searchController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (_) {

        return AlertDialog(

          title: Text("Search Message"),

          content: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Type message text...",
            ),
          ),

          actions: [

            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            ElevatedButton(
              child: Text("Search"),
              onPressed: () {

                String q =
                    searchController.text.toLowerCase();

                setState(() {

                  filteredMessages = messages.where((m) {

                    String msg =
                        (m["message"] ?? "").toLowerCase();

                    return msg.contains(q);

                  }).toList();

                });

                Navigator.pop(context);

              },
            ),

            ElevatedButton(
              child: Text("Reset"),
              onPressed: () {

                setState(() {
                  filteredMessages = messages;
                });

                Navigator.pop(context);

              },
            )

          ],
        );

      },
    );

  }

  Future<void> sendTextMessage() async {

    if (messageController.text.isEmpty) return;

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String? token = prefs.getString("token");

    final response = await http.post(
      Uri.parse("http://localhost:5000/api/message/send"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "receiver_id": widget.otherUserId,
        "message": messageController.text.trim(),
      }),
    );

    if (response.statusCode == 201) {

      messageController.clear();
      fetchMessages();

    }

  }

  Future<void> sendImage() async {

    final picked =
        await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String? token = prefs.getString("token");

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("http://localhost:5000/api/message/send"),
    );

    request.headers["Authorization"] = "Bearer $token";

    request.fields["receiver_id"] =
        widget.otherUserId.toString();

    request.files.add(
      await http.MultipartFile.fromPath('file', picked.path),
    );

    var response = await request.send();

    if (response.statusCode == 201) {
      fetchMessages();
    }

  }

  String formatTime(String? time) {

    if (time == null) return "";

    DateTime dt = DateTime.parse(time);

    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";

  }

  void openFullImage(String url) {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url),
            ),
          ),
        ),
      ),
    );

  }

  Widget buildMessageBubble(Map msg) {

    final isMe = msg["sender_id"] != widget.otherUserId;

    final imageUrl =
        "http://localhost:5000/${msg["file"]}";

    return Row(
      mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [

        if (!isMe)
          Padding(
            padding: EdgeInsets.only(right: 6),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blueGrey,
              child: Text(
                widget.otherUserName[0].toUpperCase(),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

        Flexible(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 6),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [

                msg["type"] == "image"
                    ? GestureDetector(
                        onTap: () => openFullImage(imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 250,
                              maxWidth: 220,
                            ),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        msg["message"] ?? "",
                        style: TextStyle(
                          color:
                              isMe ? Colors.white : Colors.black,
                        ),
                      ),

                SizedBox(height: 4),

                Text(
                  formatTime(msg["created_at"]),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white70
                        : Colors.black54,
                  ),
                )

              ],
            ),
          ),
        ),

      ],
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.otherUserName),

        actions: [

          IconButton(
            icon: Icon(Icons.search),
            onPressed: openSearch,
          )

        ],
      ),

      body: Column(
        children: [

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredMessages.isEmpty
                    ? Center(child: Text("No messages yet"))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(10),
                        itemCount: filteredMessages.length,
                        itemBuilder: (context, index) {
                          return buildMessageBubble(
                              filteredMessages[index]);
                        },
                      ),
          ),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [

                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: sendImage,
                ),

                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type message",
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendTextMessage,
                ),

              ],
            ),
          )

        ],
      ),

    );

  }

}