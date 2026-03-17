import 'package:flutter/material.dart';
import '../services/campaign_service.dart';

class MyApplicationsScreen extends StatefulWidget {
  @override
  _MyApplicationsScreenState createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {

  final CampaignService campaignService = CampaignService();
  List applications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadApplications();
  }

  void loadApplications() async {
    final data = await campaignService.fetchMyApplications();
    setState(() {
      applications = data;
      isLoading = false;
    });
  }

  Color getStatusColor(String status) {
    if (status == "accepted") return Colors.green;
    if (status == "rejected") return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Applications")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : applications.isEmpty
              ? Center(child: Text("No applications yet"))
              : ListView.builder(
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final app = applications[index];

                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(app["title"]),
                        subtitle: Text("By: ${app["brand_name"]}"),
                        trailing: Text(
                          app["status"],
                          style: TextStyle(
                            color: getStatusColor(app["status"]),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
  return Card(
  margin: EdgeInsets.all(10),
  child: Padding(
    padding: EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          applicant["name"],
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),

        SizedBox(height: 5),

        Text("Email: ${applicant["email"]}"),

        SizedBox(height: 5),

        Text(
          "Status: ${applicant["status"] ?? "pending"}",
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.blue),
        ),

        SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () => updateStatus(
                  applicant["id"], "accepted"),
              child: Text("Accept"),
            ),

            SizedBox(width: 10),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => updateStatus(
                  applicant["id"], "rejected"),
              child: Text("Reject"),
            ),
          ],
        )
      ],
    ),
  ),
);
}