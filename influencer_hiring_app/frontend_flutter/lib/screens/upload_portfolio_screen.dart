import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UploadPortfolioScreen extends StatefulWidget {
  @override
  _UploadPortfolioScreenState createState() =>
      _UploadPortfolioScreenState();
}

class _UploadPortfolioScreenState
    extends State<UploadPortfolioScreen> {

  final String baseUrl =
      "http://localhost:5000";

  final titleController =
      TextEditingController();

  File? selectedFile;
  bool isLoading = false;

  final picker = ImagePicker();

  Future<void> pickFile() async {
    final XFile? file =
        await picker.pickImage(
            source: ImageSource.gallery);

    if (file != null) {
      setState(() {
        selectedFile = File(file.path);
      });
    }
  }

  Future<void> uploadPortfolio() async {

    if (selectedFile == null ||
        titleController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
            content:
                Text("Fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? token =
        prefs.getString("token");

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/api/portfolio"),
    );

    request.headers["Authorization"] =
        "Bearer $token";

    request.fields["title"] =
        titleController.text.trim();

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        selectedFile!.path,
      ),
    );

    var response = await request.send();

    setState(() => isLoading = false);

    if (response.statusCode == 201) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
            content:
                Text("Upload failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar:
          AppBar(title: Text("Upload Portfolio")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Title",
                border:
                    OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: pickFile,
              child: Text("Select Image"),
            ),

            if (selectedFile != null)
              Padding(
                padding:
                    EdgeInsets.only(top: 10),
                child: Text(
                    "File selected"),
              ),

            SizedBox(height: 20),

            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed:
                        uploadPortfolio,
                    child:
                        Text("Upload"),
                  )
          ],
        ),
      ),
    );
  }
}