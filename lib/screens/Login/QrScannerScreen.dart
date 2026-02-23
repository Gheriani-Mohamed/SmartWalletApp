import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'; // ← ADD THIS

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _emailController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isProcessing = false;
  MobileScannerController? _controller;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWebScreen() : _buildMobileScanner();
  }

  // [Keep all your existing _buildWebScreen, _imageSourceButton methods as-is]

  Widget _buildWebScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Member'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Scan QR from Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Upload a photo of the member\'s QR code', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _imageSourceButton(icon: Icons.photo_library, label: 'Gallery', color: Colors.blue, onTap: () => _pickAndDecodeQr(ImageSource.gallery))),
                const SizedBox(width: 12),
                Expanded(child: _imageSourceButton(icon: Icons.camera_alt, label: 'Camera', color: Colors.green, onTap: () => _pickAndDecodeQr(ImageSource.camera))),
              ],
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 24),
              const Center(child: Column(children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Reading QR code...')])),
            ],
            const SizedBox(height: 32),
            const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(color: Colors.grey))), Expanded(child: Divider())]),
            const SizedBox(height: 32),
            const Text('Enter Email Manually', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Type the member\'s email address directly', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'example@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppConstants.primaryGreen, width: 2)),
              ),
              onSubmitted: (_) => _submitEmail(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitEmail,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Member', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageSourceButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(children: [Icon(icon, color: color, size: 36), const SizedBox(height: 8), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14))]),
      ),
    );
  }

  Future<void> _pickAndDecodeQr(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;

      setState(() => _isProcessing = true);
      final bytes = await picked.readAsBytes();
      final result = await _decodeQrFromImage(picked.path, bytes);
      setState(() => _isProcessing = false);

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No QR code found in this image. Try a clearer photo.'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      try {
        final data = json.decode(result);
        final email = data['email'] as String?;
        final name = data['name'] as String?;

        if (email == null || email.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('QR code found but no email detected. Is this a Smart Wallet QR?'), backgroundColor: Colors.red),
            );
          }
          return;
        }
        if (mounted) _showConfirmSheet(email, name ?? email);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This QR code is not from Smart Wallet.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not read image: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// ✅ FIXED - Decodes QR from image using Google ML Kit
  Future<String?> _decodeQrFromImage(String path, Uint8List bytes) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final barcodeScanner = BarcodeScanner();
      final barcodes = await barcodeScanner.processImage(inputImage);
      await barcodeScanner.close();

      if (barcodes.isEmpty) return null;
      return barcodes.first.rawValue;
    } catch (e) {
      print('Error decoding QR: $e');
      return null;
    }
  }

  void _submitEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email address'), backgroundColor: Colors.red));
      return;
    }
    Navigator.pop(context, email);
  }

  void _showConfirmSheet(String email, String name) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle), child: const Icon(Icons.check_circle, color: Colors.green, size: 40)),
            const SizedBox(height: 16),
            const Text('User Found!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: AppConstants.primaryGreen, child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text(email, style: TextStyle(fontSize: 13, color: Colors.grey[600]))])),
                  Icon(Icons.qr_code, color: AppConstants.primaryGreen, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context, email);
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Member'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileScanner() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Member QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.photo_library), onPressed: () => _pickAndDecodeQr(ImageSource.gallery)),
          IconButton(icon: const Icon(Icons.flash_on), onPressed: () => _controller?.toggleTorch()),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller!, onDetect: _onDetect),
          _buildOverlay(),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: const Text('Point camera at a Smart Wallet QR code', style: TextStyle(color: Colors.white, fontSize: 14)))),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;

    try {
      final data = json.decode(raw);
      final email = data['email'] as String?;
      final name = data['name'] as String?;

      if (email == null || email.isEmpty) {
        _showError('Invalid QR code — no email found.');
        return;
      }

      setState(() => _scanned = true);
      _controller?.stop();
      _showConfirmSheet(email, name ?? email);
    } catch (_) {
      _showError('This QR code is not from Smart Wallet.');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Widget _buildOverlay() {
    return CustomPaint(painter: _ScanOverlayPainter(), child: const SizedBox.expand());
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const windowSize = 250.0;
    const cornerRadius = 16.0;
    const cornerLength = 32.0;
    const cornerWidth = 4.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2 - 40;
    final left = centerX - windowSize / 2;
    final top = centerY - windowSize / 2;
    final right = centerX + windowSize / 2;
    final bottom = centerY + windowSize / 2;

    final windowRect = RRect.fromLTRBR(left, top, right, bottom, const Radius.circular(cornerRadius));
    final overlayPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height))..addRRect(windowRect)..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, Paint()..color = Colors.black.withOpacity(0.6));

    final p = Paint()..color = AppConstants.primaryGreen..strokeWidth = cornerWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;

    canvas.drawPath(Path()..moveTo(left + cornerLength, top)..lineTo(left + cornerRadius, top)..arcToPoint(Offset(left, top + cornerRadius), radius: const Radius.circular(cornerRadius))..lineTo(left, top + cornerLength), p);
    canvas.drawPath(Path()..moveTo(right - cornerLength, top)..lineTo(right - cornerRadius, top)..arcToPoint(Offset(right, top + cornerRadius), radius: const Radius.circular(cornerRadius), clockwise: false)..lineTo(right, top + cornerLength), p);
    canvas.drawPath(Path()..moveTo(left, bottom - cornerLength)..lineTo(left, bottom - cornerRadius)..arcToPoint(Offset(left + cornerRadius, bottom), radius: const Radius.circular(cornerRadius), clockwise: false)..lineTo(left + cornerLength, bottom), p);
    canvas.drawPath(Path()..moveTo(right, bottom - cornerLength)..lineTo(right, bottom - cornerRadius)..arcToPoint(Offset(right - cornerRadius, bottom), radius: const Radius.circular(cornerRadius))..lineTo(right - cornerLength, bottom), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}