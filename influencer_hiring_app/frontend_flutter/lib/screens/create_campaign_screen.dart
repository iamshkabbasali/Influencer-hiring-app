import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class CreateCampaignScreen extends StatefulWidget {
  @override
  _CreateCampaignScreenState createState() =>
      _CreateCampaignScreenState();
}

class _CreateCampaignScreenState
    extends State<CreateCampaignScreen> {

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final budgetController = TextEditingController();

  File? selectedImage;
  bool isLoading = false;

  final picker = ImagePicker();

  Future<void> pickImage() async {
    final picked =
        await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> createCampaign() async {

    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Title & Description required")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs =
          await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not authenticated")),
        );
        setState(() => isLoading = false);
        return;
      }

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("http://localhost:5000/api/campaign/create"),
      );

      request.headers["Authorization"] = "Bearer $token";

      request.fields["title"] =
          titleController.text.trim();
      request.fields["description"] =
          descriptionController.text.trim();
      request.fields["budget"] =
          budgetController.text.trim();

      if (selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "image", // MUST match backend upload.single('image')
            selectedImage!.path,
          ),
        );
      }

      var response = await request.send();

      final respStr =
          await response.stream.bytesToString();

      print("CREATE STATUS: ${response.statusCode}");
      print("CREATE BODY: $respStr");

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Campaign Created ✅")),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $respStr")),
        );
      }

    } catch (e) {
      print("CREATE ERROR: $e");
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server Error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Campaign"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: selectedImage == null
                    ? Center(child: Text("Tap to select image"))
                    : ClipRRect(
                        borderRadius:
                            BorderRadius.circular(10),
                        child: Image.file(
                          selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 20),

            TextField(
              controller: titleController,
              decoration:
                  InputDecoration(labelText: "Campaign Title"),
            ),

            SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration:
                  InputDecoration(labelText: "Description"),
            ),

            SizedBox(height: 10),

            TextField(
              controller: budgetController,
              decoration:
                  InputDecoration(labelText: "Budget (Optional)"),
            ),

            SizedBox(height: 25),

            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 14),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: createCampaign,
                    child: Text("Create Campaign"),
                  ),
          ],
        ),
      ),
    );
  }
}