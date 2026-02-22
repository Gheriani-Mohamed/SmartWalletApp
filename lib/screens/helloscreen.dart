import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/AuthService.dart';
import 'package:smart_wallet_app/screens/Login/loginScrenn.dart';
import 'package:smart_wallet_app/screens/Wallet/walletListScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authService.isLoggedIn(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if logged in
        if (snapshot.data == true) {
          // User is logged in, get userId and go to WalletList
          return FutureBuilder<String?>(
            future: _authService.getUserId(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                return WalletListScreen(userId: userSnapshot.data!);
              }

              // No userId found, logout and go to login
              _authService.logout();
              return const LoginScreen();
            },
          );
        }

        // Not logged in, go to login
        return const LoginScreen();
      },
    );
  }
}