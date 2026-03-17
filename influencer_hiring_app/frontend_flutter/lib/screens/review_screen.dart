import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReviewScreen extends StatefulWidget {
  final int campaignId;
  final int revieweeId;
  final String revieweeName;

  const ReviewScreen({
    Key? key,
    required this.campaignId,
    required this.revieweeId,
    required this.revieweeName,
  }) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int selectedRating = 0;
  final TextEditingController commentController = TextEditingController();

  List reviews = [];
  bool isLoadingReviews = true;
  bool isSubmitting = false;

  final String baseUrl = "http://localhost:5000";
@override
  void initState() {
    super.initState();
    fetchReviews();
  }

  // ===============================
  // FETCH ALL REVIEWS
  // ===============================
  Future<void> fetchReviews() async {
    setState(() => isLoadingReviews = true);

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/campaign/reviews/${widget.revieweeId}"),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          reviews = jsonDecode(response.body);
          isLoadingReviews = false;
        });
      } else {
        setState(() => isLoadingReviews = false);
      }
    } catch (e) {
      setState(() => isLoadingReviews = false);
    }
  }

  // ===============================
  // SUBMIT REVIEW
  // ===============================
  Future<void> submitReview() async {
    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select rating")),
      );
      return;
    }

    if (isSubmitting) return;

    setState(() => isSubmitting = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final response = await http.post(
        Uri.parse("$baseUrl/api/campaign/review"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "campaign_id": widget.campaignId,
          "reviewee_id": widget.revieweeId,
          "rating": selectedRating,
          "comment": commentController.text.trim()
        }),
      );

      if (response.statusCode == 201) {
        commentController.clear();

        setState(() {
          selectedRating = 0;
        });

        await fetchReviews();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review submitted ⭐")),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["error"] ?? "Error")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error")),
      );
    }

    setState(() => isSubmitting = false);
  }

  // ===============================
  // STAR DISPLAY (FOR REVIEW LIST)
  // ===============================
  Widget buildStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  // ===============================
  // STAR SELECTOR (FOR SUBMIT)
  // ===============================
  Widget buildStarSelector(int index) {
    return IconButton(
      icon: Icon(
        Icons.star,
        size: 35,
        color: selectedRating >= index ? Colors.amber : Colors.grey,
      ),
      onPressed: () {
        setState(() {
          selectedRating = index;
        });
      },
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reviews - ${widget.revieweeName}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ⭐ WRITE REVIEW SECTION
            const Text(
              "Write a Review",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildStarSelector(1),
                buildStarSelector(2),
                buildStarSelector(3),
                buildStarSelector(4),
                buildStarSelector(5),
              ],
            ),

            const SizedBox(height: 10),

            TextField(
              controller: commentController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Write your review",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : submitReview,
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Submit Review"),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            // 📄 REVIEW LIST SECTION
            const Text(
              "All Reviews",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            isLoadingReviews
                ? const Center(child: CircularProgressIndicator())
                : reviews.isEmpty
                    ? const Text("No reviews yet")
                    : Column(
                        children: reviews.map((r) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildStars(r["rating"]),
                                  const SizedBox(height: 6),
                                  Text(r["comment"] ?? ""),
                                  const SizedBox(height: 6),
                                  Text(
                                    "- ${r["reviewer_name"]}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
          ],
        ),
      ),
    );
  }
}