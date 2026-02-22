import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smart_wallet_app/services/recepitScannerService.dart';
import 'package:smart_wallet_app/services/Transaction_service.dart';

class ReceiptScannerScreen extends StatefulWidget {
  final String userId;
  final String walletId;
  final String defaultCategoryId;

  const ReceiptScannerScreen({
    Key? key,
    required this.userId,
    required this.walletId,
    required this.defaultCategoryId,
  }) : super(key: key);

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final ReceiptScannerService _scanner = ReceiptScannerService();
  final TransactionService _transactionService = TransactionService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  ReceiptData? _receiptData;

  bool _isScanning = false;
  bool _isSaving = false;
  String? _error;

  // Editable fields
  late TextEditingController _amountCtrl;
  late TextEditingController _descCtrl;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _scanner.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ─── Image Picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _receiptData = null;
      _error = null;
    });

    await _scanReceipt();
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Scanning ───────────────────────────────────────────────────────────────

  Future<void> _scanReceipt() async {
    if (_imageFile == null) return;
    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      final data = await _scanner.scanReceipt(_imageFile!);
      setState(() {
        _receiptData = data;
        _amountCtrl.text = data.totalAmount?.toStringAsFixed(2) ?? '';
        _descCtrl.text = data.merchantName ?? '';
        _selectedDate = data.date ?? DateTime.now();
      });
    } catch (e) {
      setState(() => _error = 'Could not scan receipt: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  // ─── Saving ─────────────────────────────────────────────────────────────────

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      _showSnack('Please enter a valid amount');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _transactionService.createTransaction(
        userId: widget.userId,
        walletId: widget.walletId,
        categoryId: widget.defaultCategoryId,
        amount: amount,
        type: 'expense',
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        date: _selectedDate,
      );
      if (mounted) {
        _showSnack('Transaction saved!', success: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnack('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  // ─── Date Picker ────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        actions: [
          if (_receiptData != null)
            TextButton(
              onPressed: _isSaving ? null : _saveTransaction,
              child: _isSaving
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image Preview ──
            _ImagePreviewCard(
              imageFile: _imageFile,
              isScanning: _isScanning,
              onTap: _showPickerSheet,
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _error!),
            ],

            // ── Parsed Fields ──
            if (_receiptData != null) ...[
              const SizedBox(height: 20),
              const Text('Receipt Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildField('Amount', _amountCtrl, prefixText: '\$',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              _buildField('Description / Merchant', _descCtrl),
              const SizedBox(height: 12),
              _DatePickerRow(date: _selectedDate, onTap: _pickDate),

              // Line items summary
              if (_receiptData!.lineItems.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Detected Items',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._receiptData!.lineItems.map((item) => _LineItemTile(item: item)),
              ],
            ],

            // ── Empty State ──
            if (_imageFile == null)
              _EmptyState(onTap: _showPickerSheet),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      String label,
      TextEditingController ctrl, {
        String? prefixText,
        TextInputType? keyboardType,
      }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

// ─── Sub-Widgets ──────────────────────────────────────────────────────────────

class _ImagePreviewCard extends StatelessWidget {
  final File? imageFile;
  final bool isScanning;
  final VoidCallback onTap;

  const _ImagePreviewCard(
      {required this.imageFile, required this.isScanning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(imageFile!, fit: BoxFit.cover),
              )
            else
              const Center(child: Icon(Icons.receipt_long, size: 60, color: Colors.grey)),
            if (isScanning)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 10),
                      Text('Scanning...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(8)),
      child: Text(message, style: TextStyle(color: Colors.red.shade700)),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DatePickerRow({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
            const SizedBox(width: 10),
            Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _LineItemTile extends StatelessWidget {
  final ReceiptLineItem item;
  const _LineItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(item.name)),
          if (item.amount != null)
            Text('\$${item.amount!.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const Text('Tap the box above to scan a receipt',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan Receipt'),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          ),
        ],
      ),
    );
  }
}