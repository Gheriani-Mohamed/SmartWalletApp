import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/AuthService.dart';
import 'package:smart_wallet_app/models/user_model.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:smart_wallet_app/screens/Login/loginScrenn.dart';
import 'package:smart_wallet_app/screens/Wallet/walletListScreen.dart';
import 'package:smart_wallet_app/screens/Analytics/GlobalAnalyticScrenn.dart';

import '../screens/Login/profileScreen.dart';

class AppDrawer extends StatelessWidget {
  final String userId;

  const AppDrawer({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Drawer(
      child: Column(
        children: [
          // Header with user info
          FutureBuilder<UserModel>(
            future: authService.getCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final user = snapshot.data!;
                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryGreen,
                        AppConstants.primaryGreen.withOpacity(0.7)
                      ],
                    ),
                  ),
                  accountName: Text(
                    user.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(user.email),
                  currentAccountPicture: _buildAvatar(user),
                );
              }
              return DrawerHeader(
                decoration:
                BoxDecoration(color: AppConstants.primaryGreen),
                child: const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
              );
            },
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'My Wallets',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              WalletListScreen(userId: userId)),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Analytics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            GlobalAnalyticsScreen(userId: userId),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildDrawerItem(
                  context,
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: userId),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Settings screen coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Help screen coming soon!')),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),

          // Logout at bottom
          const Divider(height: 1),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            color: Colors.red,
            onTap: () => _confirmLogout(context, authService),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserModel user) {
    // Profile image is stored as base64 string
    if (user.profileImage != null && user.profileImage!.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(user.profileImage!);
        return CircleAvatar(
          backgroundColor: Colors.white,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {
        // base64 decode failed, fall through to initials
      }
    }

    // Fallback to initials
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 32,
          color: AppConstants.primaryGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        Color? color,
      }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontSize: 16)),
      onTap: onTap,
    );
  }

  void _confirmLogout(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Smart Wallet',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(Icons.account_balance_wallet,
          size: 48, color: AppConstants.primaryGreen),
      children: [
        const Text('Manage your finances with ease.'),
        const SizedBox(height: 8),
        const Text(
            'Track expenses, set budgets, and achieve your saving goals.'),
      ],
    );
  }
}