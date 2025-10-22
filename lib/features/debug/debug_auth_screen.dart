import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';
import '../../core/providers/user_provider.dart';

/// Debug screen to check authentication state
/// Add this route temporarily to help debug login issues
class DebugAuthScreen extends StatelessWidget {
  const DebugAuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Auth State'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔍 Authentication Debug Info',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use this screen to check your authentication state',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // UserProvider State
            _buildSection(
              context,
              title: 'UserProvider State',
              icon: Icons.person,
              color: Colors.blue,
              children: [
                _buildInfoRow('isLoggedIn', '${userProvider.isLoggedIn}', 
                  userProvider.isLoggedIn ? Colors.green : Colors.red),
                _buildInfoRow('isLoading', '${userProvider.isLoading}', 
                  userProvider.isLoading ? Colors.orange : Colors.grey),
                _buildInfoRow('User ID', userProvider.user?.id ?? 'null', Colors.black87),
                _buildInfoRow('User Email', userProvider.user?.email ?? 'null', Colors.black87),
                _buildInfoRow('User Name', userProvider.user?.name ?? 'null', Colors.black87),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Firebase Auth State
            _buildSection(
              context,
              title: 'Firebase Auth State',
              icon: Icons.local_fire_department,
              color: Colors.orange,
              children: [
                _buildInfoRow('User Exists', '${firebaseUser != null}', 
                  firebaseUser != null ? Colors.green : Colors.red),
                _buildInfoRow('Firebase UID', firebaseUser?.uid ?? 'null', Colors.black87),
                _buildInfoRow('Firebase Email', firebaseUser?.email ?? 'null', Colors.black87),
                _buildInfoRow('Email Verified', '${firebaseUser?.emailVerified ?? false}', 
                  firebaseUser?.emailVerified == true ? Colors.green : Colors.orange),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status Summary
            _buildStatusSummary(context, userProvider, firebaseUser),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            _buildActionButtons(context, userProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary(
    BuildContext context,
    UserProvider userProvider,
    firebase_auth.User? firebaseUser,
  ) {
    final bool authOk = firebaseUser != null && userProvider.isLoggedIn;
    final bool authMismatch = (firebaseUser != null) != userProvider.isLoggedIn;

    return Card(
      color: authOk 
          ? Colors.green.shade50 
          : authMismatch 
              ? Colors.orange.shade50 
              : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  authOk 
                      ? Icons.check_circle 
                      : authMismatch 
                          ? Icons.warning 
                          : Icons.error,
                  color: authOk 
                      ? Colors.green 
                      : authMismatch 
                          ? Colors.orange 
                          : Colors.red,
                ),
                const SizedBox(width: 12),
                Text(
                  authOk 
                      ? '✅ Authentication OK' 
                      : authMismatch 
                          ? '⚠️ Auth State Mismatch' 
                          : '❌ Not Authenticated',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (authMismatch) ...[
              const SizedBox(height: 12),
              Text(
                'Firebase Auth and UserProvider are out of sync. This could cause login issues.',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Force rebuild of this widget to show latest state
            (context as Element).markNeedsBuild();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Refreshed display')),
            );
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh State'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
            if (firebaseUser != null) {
              await firebaseUser.reload();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reloaded Firebase user')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No Firebase user to reload')),
              );
            }
          },
          icon: const Icon(Icons.sync),
          label: const Text('Reload Firebase User'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            _printDebugInfo(userProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Debug info printed to console'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.bug_report),
          label: const Text('Print Debug Info to Console'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  void _printDebugInfo(UserProvider userProvider) {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    
    print('\n========== DEBUG AUTH INFO ==========');
    print('Timestamp: ${DateTime.now()}');
    print('');
    print('UserProvider:');
    print('  - isLoggedIn: ${userProvider.isLoggedIn}');
    print('  - isLoading: ${userProvider.isLoading}');
    print('  - user.id: ${userProvider.user?.id}');
    print('  - user.email: ${userProvider.user?.email}');
    print('  - user.name: ${userProvider.user?.name}');
    print('');
    print('Firebase Auth:');
    print('  - currentUser exists: ${firebaseUser != null}');
    print('  - uid: ${firebaseUser?.uid}');
    print('  - email: ${firebaseUser?.email}');
    print('  - emailVerified: ${firebaseUser?.emailVerified}');
    print('  - displayName: ${firebaseUser?.displayName}');
    print('');
    print('Status:');
    if (firebaseUser != null && userProvider.isLoggedIn) {
      print('  ✅ Both Firebase and UserProvider show logged in');
    } else if (firebaseUser != null && !userProvider.isLoggedIn) {
      print('  ⚠️ Firebase has user but UserProvider says not logged in');
    } else if (firebaseUser == null && userProvider.isLoggedIn) {
      print('  ⚠️ UserProvider says logged in but no Firebase user');
    } else {
      print('  ❌ Not logged in (both agree)');
    }
    print('=====================================\n');
  }
}
