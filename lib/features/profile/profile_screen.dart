import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/audio_provider.dart';
import '../../core/utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          
          if (user == null) {
            return const Center(
              child: Text('User not found'),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              Text(
                                user.email,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              _buildBadge(user.points),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Stats section
                Text(
                  'Your Stats',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatRow(
                          context,
                          'Total Points',
                          user.points.toString(),
                          Icons.stars,
                        ),
                        const Divider(),
                        _buildStatRow(
                          context,
                          'Member Since',
                          Utils.formatDate(user.createdAt),
                          Icons.calendar_today,
                        ),
                        const Divider(),
                        _buildStatRow(
                          context,
                          'Completed Resources',
                          user.completedResources.length.toString(),
                          Icons.book,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Settings section
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      _buildThemeToggle(context),
                      const Divider(),
                      _buildVoiceSettings(context),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Account section
                Text(
                  'Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit Profile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to edit profile screen
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: () async {
                          await userProvider.logout();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // About section
                Text(
                  'About',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('About ArguMentor'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Show about dialog
                          showAboutDialog(
                            context: context,
                            applicationName: 'ArguMentor',
                            applicationVersion: '1.0.0',
                            applicationIcon: const FlutterLogo(),
                            applicationLegalese: '© 2025 ArguMentor',
                            children: [
                              const Text(
                                'ArguMentor is an AI-powered debate coach that helps you improve your debating skills through real-time debates, personalized feedback, and skill-specific learning roadmaps.',
                              ),
                            ],
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to privacy policy screen
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.description),
                        title: const Text('Terms of Service'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to terms of service screen
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadge(int points) {
    final badgeLevel = Utils.getBadgeLevel(points);
    
    Color badgeColor;
    switch (badgeLevel) {
      case 'Platinum':
        badgeColor = Colors.blueGrey;
        break;
      case 'Gold':
        badgeColor = Colors.amber;
        break;
      case 'Silver':
        badgeColor = Colors.grey;
        break;
      case 'Bronze':
        badgeColor = Colors.brown;
        break;
      default:
        badgeColor = Colors.green;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$badgeLevel Debater',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SwitchListTile(
          title: const Text('Dark Mode'),
          secondary: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          ),
          value: themeProvider.isDarkMode,
          onChanged: (value) {
            themeProvider.setDarkMode(value);
          },
        );
      },
    );
  }

  Widget _buildVoiceSettings(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        return ExpansionTile(
          leading: const Icon(Icons.settings_voice),
          title: const Text('Voice Settings'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Speech Rate',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Slider(
                    value: audioProvider.speechRate,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: audioProvider.speechRate.toStringAsFixed(1),
                    onChanged: (value) {
                      audioProvider.setSpeechRate(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Voice Pitch',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Slider(
                    value: audioProvider.pitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: audioProvider.pitch.toStringAsFixed(1),
                    onChanged: (value) {
                      audioProvider.setPitch(value);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
