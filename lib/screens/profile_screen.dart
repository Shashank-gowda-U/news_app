// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:news_app/providers/auth_provider.dart';
import 'package:news_app/screens/create/my_posts_screen.dart';
import 'package:news_app/screens/edit_profile_screen.dart';
import 'package:news_app/screens/edit_tags_screen.dart';
// --- NEW IMPORT ---
import 'package:news_app/screens/following_screen.dart';
// --- END OF NEW IMPORT ---
import 'package:news_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:news_app/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final UserModel? user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ));
            },
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
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
                'Anchor Dashboard',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Posts', user.totalPosts.toString()),
                  _buildStatColumn('Followers', user.totalFollowers.toString()),
                  _buildStatColumn('Total Likes', user.totalLikes.toString()),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                context,
                icon: Icons.article_outlined,
                title: 'My Posts',
                subtitle: 'Edit or delete your published posts',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const MyPostsScreen(),
                  ));
                },
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                context,
                icon: Icons.cake_outlined,
                title: 'Date of Birth',
                subtitle: user.dateOfBirth == null || user.dateOfBirth!.isEmpty
                    ? 'Not set'
                    : user.dateOfBirth!,
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

            // --- MODIFIED "FOLLOWING" BUTTON ---
            _buildInfoCard(
              context,
              icon: Icons.people_alt_outlined,
              title: 'Following ${user.followingAnchors.length} Anchors',
              subtitle: 'View anchors you follow',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const FollowingScreen(),
                ));
              },
            ),
            // --- END OF MODIFICATION ---

            const Divider(height: 32),
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

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

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
