// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/screens/edit_tags_screen.dart';
import 'package:news_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the theme and auth providers
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user; // Get the dummy user

    // A fallback if the user is somehow null (shouldn't happen)
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Error: No user found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          // The new Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- User Info Section ---
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user.profilePicUrl),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    user.location,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Divider(height: 32),

            // --- Anchor Info Section ---
            if (user.isAnchor) ...[
              Text(
                'Anchor Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildInfoCard(
                context,
                icon: Icons.cake_outlined,
                title: 'Date of Birth',
                subtitle: user.dateOfBirth ?? 'Not set',
              ),
              const Divider(height: 32),
            ],

            // --- Preferences Section ---
            Text(
              'My Preferences',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildInfoCard(
              context,
              icon: Icons.label_outline,
              title: 'My Preferred Tags',
              subtitle: user.preferredTags.join(', '),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const EditTagsScreen(),
                ));
              },
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              icon: Icons.people_alt_outlined,
              title: 'Following ${user.followingAnchors.length} Anchors',
              subtitle: 'View anchors you follow',
              onTap: () {
                // TODO: Build "Following" screen
              },
            ),
            const Divider(height: 32),

            // --- App Settings Section ---
            Text(
              'App Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dark Mode',
                    style: TextStyle(fontSize: 16),
                  ),
                  Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the info cards
  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: (onTap != null) ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
