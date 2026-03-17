import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_screen.dart';
import '../main.dart';

import 'influencer_feed_screen.dart'; // CAMPAIGNS SCREEN
import 'influencer_applications_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'analytics_screen.dart';
import 'followers_feed_screen.dart'; // FOLLOWERS POSTS

class InfluencerMainScreen extends StatefulWidget {
  @override
  _InfluencerMainScreenState createState() =>
      _InfluencerMainScreenState();
}

class _InfluencerMainScreenState
    extends State<InfluencerMainScreen> {

  int _selectedIndex = 0;

  /// SCREENS
  final List<Widget> _screens = [
    InfluencerFeedScreen(), // CAMPAIGNS VISIBLE HERE
    InfluencerApplicationsScreen(),
    ChatListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> logout() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.remove("token");
    await prefs.remove("userId");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Influencer Dashboard"),
        centerTitle: true,

        actions: [

          /// HOME BUTTON → FOLLOWERS FEED
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FollowersFeedScreen(),
                ),
              );
            },
          ),

          /// SEARCH
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchScreen(),
                ),
              );
            },
          ),

          /// NOTIFICATIONS
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      NotificationScreen(),
                ),
              );
            },
          ),

          /// ANALYTICS
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AnalyticsScreen(),
                ),
              );
            },
          ),

          /// PROFILE
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () async {

              SharedPreferences prefs =
                  await SharedPreferences.getInstance();

              int? userId =
                  prefs.getInt("userId");

              if (userId != null) {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileScreen(userId: userId),
                  ),
                );

              }

            },
          ),

          /// LOGOUT
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
          ),

        ],
      ),

      /// MAIN SCREEN
      body: _screens[_selectedIndex],

      /// BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(

        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: "Applications",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Chat",
          ),

        ],
      ),
    );
  }
}