import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http';
import 'package:shared_preferences/shared_preferences.dart';

class BrandReviewsScreen extends StatefulWidget {
  @override
  State<BrandReviewsScreen> createState() =>
      _BrandReviewsScreenState();
}

class _BrandReviewsScreenState
    extends State<BrandReviewsScreen> {

  List reviews = [];
  bool isLoading = true;

  final String baseUrl =
      "http://localhost:5000";

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    String? token =
        prefs.getString("token");

    final response = await http.get(
      Uri.parse(
          "$baseUrl/api/campaign/reviews/me"),
      headers: {
        "Authorization":
            "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        reviews =
            jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Widget buildStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating
              ? Icons.star
              : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar:
          AppBar(title: Text("My Reviews")),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator())
          : reviews.isEmpty
              ? Center(
                  child:
                      Text("No reviews yet"))
              : ListView.builder(
                  padding:
                      EdgeInsets.all(12),
                  itemCount:
                      reviews.length,
                  itemBuilder:
                      (context, index) {

                    final r =
                        reviews[index];

                    return Card(
                      margin:
                          EdgeInsets.only(
                              bottom: 12),
                      child: Padding(
                        padding:
                            EdgeInsets.all(
                                15),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [

                            buildStars(
                                r["rating"]),

                            SizedBox(
                                height: 6),

                            Text(
                              r["comment"] ??
                                  "",
                            ),

                            SizedBox(
                                height: 6),

                            Text(
                              "- ${r["reviewer_name"]}",
                              style:
                                  TextStyle(
                                      fontSize:
                                          12,
                                      color:
                                          Colors
                                              .grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}