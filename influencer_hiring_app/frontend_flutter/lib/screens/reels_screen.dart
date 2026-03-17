import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http';

class ReelsScreen extends StatefulWidget {
  @override
  _ReelsScreenState createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {

  final String baseUrl = "http://localhost:5000";
  List reels = [];

  @override
  void initState() {
    super.initState();
    fetchReels();
  }

  Future<void> fetchReels() async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/posts/explore"),
    );
    setState(() {
      reels = jsonDecode(res.body);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: reels.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Image.network(
                "$baseUrl/${reels[index]["image"]}",
                fit: BoxFit.cover,
                height: double.infinity,
              ),
              Positioned(
                bottom: 40,
                left: 20,
                child: Text(
                  reels[index]["name"],
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}