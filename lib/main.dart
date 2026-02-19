import 'package:flutter/material.dart';
import 'package:smart_wallet_app/screens/WalletScreen.dart';
import 'package:smart_wallet_app/screens/helloscreen.dart';
import 'package:smart_wallet_app/utils/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Wallet',
      theme: ThemeData(
        primaryColor: AppConstants.primaryGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryGreen,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const WalletScreen(),
    );
  }
}