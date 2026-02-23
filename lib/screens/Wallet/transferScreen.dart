import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/wallet_service.dart';
import 'package:smart_wallet_app/models/wallet_model.dart';
import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/utils/constants.dart';

class TransferScreen extends StatefulWidget {
  final String userId;
  final String fromWalletId; // pre-selected source wallet

  const TransferScreen({
    super.key,
    required this.userId,
    required this.fromWalletId,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final WalletService _walletService = WalletService();
  final ApiService _apiService = ApiService();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<WalletModel> _wallets = [];
  WalletModel? _fromWallet;
  WalletModel? _toWallet;
  bool _isLoading = true;
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await _walletService.getUserWallets(widget.userId);
      if (!mounted) return;
      final fromWallet = wallets.firstWhere(
            (w) => w.id == widget.fromWalletId,
        orElse: () => wallets.first,
      );
      setState(() {
        _wallets = wallets;
        _fromWallet = fromWallet;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Failed to load wallets: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Money'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wallets.length < 2
          ? _buildNoWalletsState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Transfer arrow visual ──────────────────────────
              _buildTransferVisual(),
              const SizedBox(height: 28),

              // ── From wallet ────────────────────────────────────
              _buildSectionLabel('From Wallet', Icons.account_balance_wallet),
              const SizedBox(height: 10),
              _buildWalletDropdown(
                value: _fromWallet,
                excludeId: _toWallet?.id,
                onChanged: (w) => setState(() => _fromWallet = w),
              ),
              const SizedBox(height: 8),
              if (_fromWallet != null)
                _buildBalanceBadge(_fromWallet!),

              const SizedBox(height: 20),

              // ── To wallet ──────────────────────────────────────
              _buildSectionLabel('To Wallet', Icons.account_balance_wallet_outlined),
              const SizedBox(height: 10),
              _buildWalletDropdown(
                value: _toWallet,
                excludeId: _fromWallet?.id,
                onChanged: (w) => setState(() => _toWallet = w),
                hint: 'Select destination wallet',
              ),
              if (_toWallet != null) ...[
                const SizedBox(height: 8),
                _buildBalanceBadge(_toWallet!),
              ],

              const SizedBox(height: 24),

              // ── Amount ─────────────────────────────────────────
              _buildSectionLabel('Amount', Icons.attach_money),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '\$ ',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppConstants.primaryGreen, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter an amount';
                  final amount = double.tryParse(value.trim());
                  if (amount == null) return 'Please enter a valid number';
                  if (amount <= 0) return 'Amount must be greater than zero';
                  if (_fromWallet != null && amount > _fromWallet!.balance) {
                    return 'Insufficient balance (available: \$${_fromWallet!.balance.toStringAsFixed(2)})';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Note (optional) ────────────────────────────────
              _buildSectionLabel('Note (Optional)', Icons.note_outlined),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'e.g. Monthly savings transfer',
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppConstants.primaryGreen, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Transfer button ────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isTransferring ? null : _confirmTransfer,
                  icon: _isTransferring
                      ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.send),
                  label: Text(
                    _isTransferring ? 'Transferring...' : 'Transfer Money',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── UI Helpers ────────────────────────────────────────────────────────────

  Widget _buildTransferVisual() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryGreen.withOpacity(0.08),
            AppConstants.primaryGreen.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet, color: AppConstants.primaryGreen, size: 32),
          const SizedBox(width: 12),
          Column(
            children: [
              const Icon(Icons.arrow_forward, color: AppConstants.primaryGreen, size: 22),
              Text(
                _amountController.text.isEmpty
                    ? 'Select amount'
                    : '\$${_amountController.text}',
                style: const TextStyle(
                    color: AppConstants.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Icon(Icons.account_balance_wallet_outlined, color: AppConstants.primaryGreen, size: 32),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildWalletDropdown({
    required WalletModel? value,
    required void Function(WalletModel?) onChanged,
    String? excludeId,
    String hint = 'Select source wallet',
  }) {
    final options = _wallets.where((w) => w.id != excludeId).toList();
    final safeValue = options.contains(value) ? value : null;

    return DropdownButtonFormField<WalletModel>(
      value: safeValue,
      hint: Text(hint),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: options.map((wallet) {
        final icon = wallet.type == 'family'
            ? Icons.family_restroom
            : wallet.type == 'company'
            ? Icons.business
            : Icons.person;
        final color = wallet.type == 'family'
            ? Colors.blue
            : wallet.type == 'company'
            ? Colors.orange
            : AppConstants.primaryGreen;

        return DropdownMenuItem<WalletModel>(
          value: wallet,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(wallet.name,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
              Text('\$${wallet.balance.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBalanceBadge(WalletModel wallet) {
    final isLow = wallet.balance < 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLow ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isLow ? Icons.warning_amber : Icons.check_circle,
              size: 14, color: isLow ? Colors.red : Colors.green),
          const SizedBox(width: 6),
          Text(
            'Balance: \$${wallet.balance.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isLow ? Colors.red : Colors.green[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWalletsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('You need at least 2 wallets to transfer',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 8),
          const Text('Create another wallet first'),
        ],
      ),
    );
  }

  // ── Transfer Logic ────────────────────────────────────────────────────────

  void _confirmTransfer() {
    if (!_formKey.currentState!.validate()) return;
    if (_toWallet == null) {
      _showSnackBar('Please select a destination wallet', Colors.orange);
      return;
    }

    final amount = double.parse(_amountController.text.trim());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.send, color: AppConstants.primaryGreen),
            SizedBox(width: 8),
            Text('Confirm Transfer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _confirmRow('From', _fromWallet!.name),
            const SizedBox(height: 8),
            _confirmRow('To', _toWallet!.name),
            const SizedBox(height: 8),
            _confirmRow('Amount', '\$${amount.toStringAsFixed(2)}'),
            if (_descriptionController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _confirmRow('Note', _descriptionController.text.trim()),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeTransfer(amount);
            },
            icon: const Icon(Icons.check),
            label: const Text('Confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Future<void> _executeTransfer(double amount) async {
    if (!mounted) return;
    setState(() => _isTransferring = true);

    bool success = false;
    String? errorMsg;

    try {
      await _apiService.post('/wallets/transfer', {
        'fromWalletId': _fromWallet!.id,
        'toWalletId': _toWallet!.id,
        'amount': amount,
        'userId': widget.userId,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      });
      success = true;
    } catch (e) {
      errorMsg = e.toString();
    }

    if (!mounted) return;
    setState(() => _isTransferring = false);

    if (success) {
      _showSnackBar(
        'Transferred \$${amount.toStringAsFixed(2)} to ${_toWallet!.name}!',
        Colors.green,
      );
      Navigator.pop(context, true);
    } else {
      _showSnackBar('Transfer failed: $errorMsg', Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}