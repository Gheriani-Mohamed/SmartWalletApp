import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_wallet_app/models/user_model.dart';
import 'package:smart_wallet_app/utils/constants.dart';

class QrProfileScreen extends StatelessWidget {
  final UserModel user;

  const QrProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // QR encodes a simple JSON string with userId and email
    final qrData = '{"userId":"${user.id}","email":"${user.email}","name":"${user.name}"}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My QR Code'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Instruction card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.primaryGreen.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppConstants.primaryGreen, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Share this QR code so others can add you as a wallet member instantly — no need to type your email.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // QR Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar + name header
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppConstants.primaryGreen,
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // QR Code
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1B5E20),
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppConstants.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Scan me label
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner,
                            size: 16, color: AppConstants.primaryGreen),
                        const SizedBox(width: 6),
                        Text(
                          'Scan to add as wallet member',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Copy email button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: user.email));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email copied to clipboard!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: Text('Copy email  (${user.email})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.primaryGreen,
                  side: BorderSide(
                      color: AppConstants.primaryGreen, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}