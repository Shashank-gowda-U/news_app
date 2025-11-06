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
      // --- REMOVED: floatingActionButton and floatingActionButtonLocation ---

      // --- MODIFIED: BottomAppBar ---
      bottomNavigationBar: BottomAppBar(
        // Removed the shape and notchMargin
        child: Row(
          // Use spaceAround to evenly space all 5 items
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildBottomNavIcon(Icons.public_outlined, 'Global', 0),
            _buildBottomNavIcon(Icons.people_outline, 'Local', 1),

            // --- NEW: This is the replacement "+" button ---
            ElevatedButton(
              onPressed: _onCreatePostTapped,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
                backgroundColor:
                    Theme.of(context).colorScheme.primary, // Blue color
                foregroundColor:
                    Theme.of(context).colorScheme.onPrimary, // White "+"
              ),
              child: const Icon(Icons.add),
            ),
            // --- END OF NEW BUTTON ---

            // --- CHANGED: Label is now "Dev News" ---
            _buildBottomNavIcon(Icons.developer_mode_outlined, 'Dev News', 2),
            _buildBottomNavIcon(Icons.person_outline, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the icons
  Widget _buildBottomNavIcon(IconData icon, String label, int index) {
    final bool isSelected = (_selectedIndex == index);
    final Color color =
        isSelected ? Theme.of(context).colorScheme.primary : Colors.grey;

    return MaterialButton(
      minWidth: 40,
      onPressed: () {
        _onItemTapped(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
