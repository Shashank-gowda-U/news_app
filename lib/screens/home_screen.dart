// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/screens/ai_news_feed_screen.dart';
import 'package:news_app/screens/create/become_anchor_screen.dart';
import 'package:news_app/screens/create/create_post_screen.dart';
import 'package:news_app/screens/developer_news_screen.dart';
import 'package:news_app/screens/local_anchors_screen.dart';
import 'package:news_app/screens/profile_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    AiNewsFeedScreen(),
    LocalAnchorsScreen(),
    DeveloperNewsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCreatePostTapped() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.isAnchor ?? false) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const BecomeAnchorScreen(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreatePostTapped,
        // --- CHANGE: Set elevation to 0 to remove shadow ---
        elevation: 0.0,
        highlightElevation: 0.0,
        // --- END OF CHANGE ---
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        // --- CHANGE: Set notchMargin to 0 to make it flush ---
        notchMargin: 0.0,
        // --- END OF CHANGE ---
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Left-side icons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBottomNavIcon(Icons.public_outlined, 'Global', 0),
                _buildBottomNavIcon(Icons.people_outline, 'Local', 1),
              ],
            ),
            // Right-side icons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBottomNavIcon(
                    Icons.developer_mode_outlined, 'Updates', 2),
                _buildBottomNavIcon(Icons.person_outline, 'Profile', 3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the icons
  Widget _buildBottomNavIcon(IconData icon, String label, int index) {
    return MaterialButton(
      minWidth: 40,
      onPressed: () {
        _onItemTapped(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _selectedIndex == index
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
