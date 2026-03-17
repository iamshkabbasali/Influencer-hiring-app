import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() =>
      _CreatePostScreenState();
}

class _CreatePostScreenState
    extends State<CreatePostScreen> {

  final String baseUrl = "http://localhost:5000";

  final captionController = TextEditingController();
  File? selectedImage;
  bool isUploading = false;

  Future<void> pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> uploadPost() async {

    if (selectedImage == null) return;

    setState(() => isUploading = true);

    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/api/posts"),
    );

    request.headers["Authorization"] =
        "Bearer $token";

    request.fields["caption"] =
        captionController.text;

    request.files.add(
      await http.MultipartFile.fromPath(
        "image",
        selectedImage!.path,
      ),
    );

    var response = await request.send();

    setState(() => isUploading = false);

    if (response.statusCode == 200) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Upload Post")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: selectedImage == null
                    ? Icon(Icons.add_a_photo, size: 50)
                    : Image.file(selectedImage!,
                        fit: BoxFit.cover),
              ),
            ),

            SizedBox(height: 15),

            TextField(
              controller: captionController,
              decoration: InputDecoration(
                labelText: "Caption",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: uploadPost,
                    child: Text("Post"),
                  ),
          ],
        ),
      ),
    );
  }
}