import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_appbar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profile',
        onLeadingPressed: () => context.pop(),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 60,
                    color: textGray,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Not logged in',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: textGray),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryGreen, accentGreen],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: white.withOpacity(0.2),
                        ),
                        child: const Icon(
                          Icons.account_circle,
                          size: 80,
                          color: white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                              color: white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Settings
                      Text(
                        'Account Settings',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsTile(
                        context,
                        'Edit Profile',
                        'Update your personal information',
                        Icons.edit_outlined,
                        () {},
                      ),
                      _buildSettingsTile(
                        context,
                        'Change Password',
                        'Update your password',
                        Icons.lock_outlined,
                        () {},
                      ),
                      _buildSettingsTile(
                        context,
                        'Notifications',
                        'Manage notification settings',
                        Icons.notifications_outlined,
                        () {},
                      ),
                      const SizedBox(height: 24),

                      // App Settings
                      Text(
                        'App Settings',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsTile(
                        context,
                        'Theme',
                        'Dark Mode / Light Mode',
                        Icons.brightness_4_outlined,
                        () {},
                      ),
                      _buildSettingsTile(
                        context,
                        'Language',
                        'Select language',
                        Icons.language_outlined,
                        () {},
                      ),
                      _buildSettingsTile(
                        context,
                        'Location',
                        'Manage your location',
                        Icons.location_on_outlined,
                        () {},
                      ),
                      const SizedBox(height: 24),

                      // Support & Info
                      Text(
                        'Support & Information',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsTile(
                        context,
                        'FAQ',
                        'Frequently Asked Questions',
                        Icons.help_outline,
                        () {},
                      ),
                      _buildSettingsTile(
                        context,
                        'Terms & Conditions',
                        'Read our terms',
                        Icons.description_outlined,
                        () {},
                      ),
                      _buildSettingsTile(
                        context,
                        'Privacy Policy',
                        'Read our privacy policy',
                        Icons.privacy_tip_outlined,
                        () {},
                      ),
                      const SizedBox(height: 24),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            authProvider.logout();
                            context.go('/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: errorRed,
                          ),
                          child: const Text('Logout'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // App Version
                      Center(
                        child: Text(
                          'AgroCare v1.0.0',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: textGray),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryGreen, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: textGray),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: textGray),
          ],
        ),
      ),
    );
  }
}
