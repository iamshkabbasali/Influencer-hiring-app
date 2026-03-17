import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentBio;
  final bool isPrivate;

  const EditProfileScreen({
    required this.currentBio,
    required this.isPrivate,
  });

  @override
  _EditProfileScreenState createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {

  final String baseUrl =
      "http://localhost:5000";

  late TextEditingController bioController;
  bool isPrivate = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    bioController =
        TextEditingController(text: widget.currentBio);
    isPrivate = widget.isPrivate;
  }

  Future<void> saveProfile() async {

    setState(() => isLoading = true);

    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final res = await http.put(
      Uri.parse("$baseUrl/api/profile/update"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "bio": bioController.text.trim(),
        "is_private": isPrivate
      }),
    );

    setState(() => isLoading = false);

    if (res.statusCode == 200) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            SwitchListTile(
              title: Text("Private Account"),
              value: isPrivate,
              onChanged: (value) {
                setState(() {
                  isPrivate = value;
                });
              },
            ),

            SizedBox(height: 20),

            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: saveProfile,
                    child: Text("Save"),
                  )
          ],
        ),
      ),
    );
  }
}