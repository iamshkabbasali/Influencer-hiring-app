import 'package:flutter/material.dart';

class PortfolioViewScreen extends StatelessWidget {

  final String imageUrl;
  final String title;
  final String description;

  const PortfolioViewScreen({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),

      body: Column(
        children: [

          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          if (description.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                description,
                style: TextStyle(fontSize: 16),
              ),
            ),

        ],
      ),
    );
  }
}