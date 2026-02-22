import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_wallet_app/services/wallet_service.dart';
import 'package:smart_wallet_app/services/RecurringTransactionService.dart';
import 'package:smart_wallet_app/services/AlertService.dart';
import 'package:smart_wallet_app/services/Transaction_service.dart';
import 'package:smart_wallet_app/services/Category_service.dart';
import 'package:smart_wallet_app/models/CategoryModel.dart';
import 'package:smart_wallet_app/services/recepitScannerService.dart';
import 'package:smart_wallet_app/services/voicetoTransactionService.dart';
import 'package:smart_wallet_app/models/wallet_model.dart';
import 'package:smart_wallet_app/models/RecurringTransaction.dart';
import 'package:smart_wallet_app/models/AlertModel.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:smart_wallet_app/screens/Wallet/editWalletScreen.dart';
import 'package:smart_wallet_app/screens/Transaction/transactionListScreen.dart';
import 'package:smart_wallet_app/screens/Budget/budgetListScreen.dart';
import 'package:smart_wallet_app/screens/ReccuringTransactions/reccuringListScreen.dart';
import 'package:smart_wallet_app/screens/saving_Goals/saving_goal_list_screen.dart';
import 'package:smart_wallet_app/screens/Analytics/AnalyticScrenn.dart';

class WalletDetailsScreen extends StatefulWidget {
  final String walletId;
  final String userId;

  const WalletDetailsScreen({
    super.key,
    required this.walletId,
    required this.userId,
  });

  @override
  State<WalletDetailsScreen> createState() => _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends State<WalletDetailsScreen> {
  final WalletService _walletService = WalletService();
  final RecurringTransactionService _recurringService = RecurringTransactionService();
  final AlertService _alertService = AlertService();
  final TransactionService _transactionService = TransactionService();
  final ReceiptScannerService _receiptScanner = ReceiptScannerService();
  final VoiceTransactionService _voiceService = VoiceTransactionService();
  final ImagePicker _imagePicker = ImagePicker();
  final _addMemberController = TextEditingController();
  int _unreadAlertsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadAlerts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndGenerateRecurring();
    });
  }

  @override
  void dispose() {
    _addMemberController.dispose();
    _receiptScanner.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadAlerts() async {
    try {
      final alerts = await _alertService.getUserAlerts(widget.userId);
      if (!mounted) return;
      final unreadCount = alerts.where((a) => !a.isRead).length;
      setState(() => _unreadAlertsCount = unreadCount);
    } catch (e) {
      if (mounted) print('Error loading alerts: $e');
    }
  }


  Future<void> _checkAndGenerateRecurring() async {
    try {
      final recurring = await _recurringService.getWalletRecurring(widget.walletId);
      final overdueList = recurring.where((r) => r.isOverdue).toList();
      final overdueCount = overdueList.length;

      if (overdueCount > 0) {
        if (!mounted) return;

        final shouldGenerate = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.repeat, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Recurring Transactions',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300), // Fixed height constraint
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You have $overdueCount pending recurring transaction${overdueCount > 1 ? 's' : ''}:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ...overdueList.take(5).map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.circle,
                              size: 6,
                              color: r.type == 'income' ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${r.description ?? 'Transaction'} (\$${r.amount.toStringAsFixed(2)})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (overdueCount > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'and ${overdueCount - 5} more...',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Generate them now?',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Later', style: TextStyle(fontSize: 13)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Generate', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        );

        if (shouldGenerate == true && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          try {
            final result = await _recurringService.generateAllUserTransactions(widget.userId);
            final generatedCount = result['totalGenerated'] ?? 0;
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Generated $generatedCount transaction(s)!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ));
            if (mounted) setState(() {});
          } catch (e) {
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error generating transactions: $e'),
              backgroundColor: Colors.red,
            ));
          }
        }
      }
    } catch (e) {
      print('Error checking recurring transactions: $e');
    }
  }

  // ─── Receipt Scanner ────────────────────────────────────────────────────────

  void _showScanReceiptOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Scan Receipt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.camera_alt, color: Colors.green),
              ),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndScanReceipt(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndScanReceipt(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndScanReceipt(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;

      // Show scanning loader
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Scanning receipt...'),
                ],
              ),
            ),
          ),
        ),
      );

      final receiptData = await _receiptScanner.scanReceipt(File(picked.path));

      if (!mounted) return;
      Navigator.pop(context); // close loader

      _showReceiptConfirmSheet(receiptData, File(picked.path));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loader if open
      _showSnackBar('Could not scan receipt: $e', Colors.red);
    }
  }

  void _showReceiptConfirmSheet(ReceiptData data, File imageFile) {
    final amountCtrl = TextEditingController(
        text: data.totalAmount?.toStringAsFixed(2) ?? '');
    final descCtrl = TextEditingController(text: data.merchantName ?? '');
    DateTime selectedDate = data.date ?? DateTime.now();
    CategoryModel? selectedCategory;
    List<CategoryModel> categories = [];
    bool loadingCategories = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Fetch categories once when sheet opens
            if (loadingCategories) {
              CategoryService().getCategoriesByType('expense').then((cats) {
                setSheetState(() {
                  categories = cats;
                  loadingCategories = false;
                });
              }).catchError((_) {
                setSheetState(() => loadingCategories = false);
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (_, scrollCtrl) => Column(
                  children: [
                    // Handle
                    const SizedBox(height: 12),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long, color: AppConstants.primaryGreen),
                          const SizedBox(width: 10),
                          const Text('Receipt Scanned',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    Expanded(
                      child: ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(imageFile,
                                height: 140, width: double.infinity, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 20),

                          // Amount field
                          TextField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description field
                          TextField(
                            controller: descCtrl,
                            decoration: InputDecoration(
                              labelText: 'Description / Merchant',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Date picker
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[50],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${selectedDate.day.toString().padLeft(2, '0')}/'
                                        '${selectedDate.month.toString().padLeft(2, '0')}/'
                                        '${selectedDate.year}',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Category Selector ──────────────────────────
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Text('Category',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700])),
                                  if (selectedCategory == null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('Required',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.red[400],
                                              fontWeight: FontWeight.w500)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (loadingCategories)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                )
                              else if (categories.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber,
                                          color: Colors.orange[700], size: 18),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text('No categories found. Please create one first.',
                                            style: TextStyle(fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: categories.map((cat) {
                                    final isSelected = selectedCategory?.id == cat.id;
                                    final color = cat.color;
                                    return GestureDetector(
                                      onTap: () => setSheetState(
                                              () => selectedCategory = isSelected ? null : cat),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? color.withOpacity(0.15)
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected ? color : Colors.grey.shade300,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _iconFromName(cat.iconName),
                                              size: 16,
                                              color: isSelected ? color : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              cat.name,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isSelected ? color : Colors.black87,
                                              ),
                                            ),
                                            if (isSelected) ...[
                                              const SizedBox(width: 4),
                                              Icon(Icons.check_circle,
                                                  size: 14, color: color),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                          // ───────────────────────────────────────────────

                          // Detected line items (read-only summary)
                          if (data.lineItems.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text('Detected Items (${data.lineItems.length})',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: data.lineItems.take(5).map((item) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.circle, size: 6, color: Colors.grey),
                                  title: Text(item.name,
                                      style: const TextStyle(fontSize: 13)),
                                  trailing: item.amount != null
                                      ? Text('\$${item.amount!.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w500))
                                      : null,
                                )).toList(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final amount = double.tryParse(amountCtrl.text);
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a valid amount'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (selectedCategory == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a category'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                Navigator.pop(context); // close sheet

                                try {
                                  await _transactionService.createTransaction(
                                    userId: widget.userId,
                                    walletId: widget.walletId,
                                    categoryId: selectedCategory!.id,
                                    amount: amount,
                                    type: 'expense',
                                    description: descCtrl.text.trim().isEmpty
                                        ? null
                                        : descCtrl.text.trim(),
                                    date: selectedDate,
                                  );

                                  if (!mounted) return;
                                  _showSnackBar('Transaction saved successfully!', Colors.green);
                                  setState(() {});
                                } catch (e) {
                                  if (!mounted) return;
                                  _showSnackBar('Failed to save: $e', Colors.red);
                                }
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('Save as Transaction',
                                  style: TextStyle(fontSize: 15)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedCategory != null
                                    ? AppConstants.primaryGreen
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _iconFromName(String name) {
    const map = {
      'restaurant': Icons.restaurant,
      'fastfood': Icons.fastfood,
      'local_grocery_store': Icons.local_grocery_store,
      'directions_car': Icons.directions_car,
      'local_gas_station': Icons.local_gas_station,
      'train': Icons.train,
      'flight': Icons.flight,
      'home': Icons.home,
      'electrical_services': Icons.electrical_services,
      'wifi': Icons.wifi,
      'local_hospital': Icons.local_hospital,
      'medication': Icons.medication,
      'school': Icons.school,
      'sports_esports': Icons.sports_esports,
      'movie': Icons.movie,
      'shopping_bag': Icons.shopping_bag,
      'checkroom': Icons.checkroom,
      'fitness_center': Icons.fitness_center,
      'pets': Icons.pets,
      'card_giftcard': Icons.card_giftcard,
      'savings': Icons.savings,
      'account_balance': Icons.account_balance,
      'work': Icons.work,
      'trending_up': Icons.trending_up,
      'attach_money': Icons.attach_money,
      'more_horiz': Icons.more_horiz,
    };
    return map[name] ?? Icons.category;
  }

  // ─── Voice Transaction ──────────────────────────────────────────────────────

  Future<void> _startVoiceTransaction() async {
    final initialized = await _voiceService.initialize();
    if (!initialized) {
      _showSnackBar('Microphone not available on this device', Colors.red);
      return;
    }

    // Fetch both expense and income categories
    List<CategoryModel> categories = [];
    try {
      final expense = await CategoryService().getCategoriesByType('expense');
      final income = await CategoryService().getCategoriesByType('income');
      categories = [...expense, ...income];
    } catch (_) {}

    if (!mounted) return;
    _showVoiceBottomSheet(categories);
  }

  void _showVoiceBottomSheet(List<CategoryModel> categories) {
    String liveText = '';
    bool isListening = false;
    bool isDone = false;
    VoiceTransactionResult? result;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> startListening() async {
              setSheetState(() {
                isListening = true;
                isDone = false;
                liveText = '';
                result = null;
              });

              await _voiceService.startListening(
                onResult: (text, isFinal) {
                  setSheetState(() => liveText = text);
                  if (isFinal) {
                    final parsed = _voiceService.parse(text, categories);
                    setSheetState(() {
                      result = parsed;
                      isListening = false;
                      isDone = true;
                    });
                  }
                },
                onDone: () => setSheetState(() => isListening = false),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Row(
                      children: [
                        const Icon(Icons.mic, color: AppConstants.primaryGreen),
                        const SizedBox(width: 8),
                        const Text('Voice Transaction',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () async {
                            await _voiceService.cancel();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Hint text
                    if (!isDone)
                      Text(
                        'Try: "Add \$12 to Food for McDonald\'s"',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    const SizedBox(height: 24),

                    // Mic button with pulse
                    GestureDetector(
                      onTap: isListening
                          ? () async {
                        await _voiceService.stopListening();
                        setSheetState(() => isListening = false);
                      }
                          : startListening,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isListening ? 90 : 72,
                        height: isListening ? 90 : 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isListening
                              ? Colors.red
                              : AppConstants.primaryGreen,
                          boxShadow: isListening
                              ? [
                            BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5),
                          ]
                              : [
                            BoxShadow(
                                color: AppConstants.primaryGreen
                                    .withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2),
                          ],
                        ),
                        child: Icon(
                          isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status text
                    Text(
                      isListening
                          ? 'Listening... tap to stop'
                          : isDone
                          ? 'Done! Review below'
                          : 'Tap to speak',
                      style: TextStyle(
                        fontSize: 13,
                        color: isListening ? Colors.red : Colors.grey[600],
                        fontWeight: isListening
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),

                    // Live transcript
                    if (liveText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '"$liveText"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700]),
                        ),
                      ),
                    ],

                    // Parsed result preview
                    if (isDone && result != null) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      _buildParsedResultCard(result!),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          // Retry
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: startListening,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Confirm
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: result!.isUsable
                                  ? () {
                                Navigator.pop(context);
                                _showVoiceConfirmSheet(
                                    result!, categories);
                              }
                                  : null,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Continue'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryGreen,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildParsedResultCard(VoiceTransactionResult result) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: result.isUsable ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result.isUsable
              ? Colors.green.shade200
              : Colors.orange.shade200,
        ),
      ),
      child: Column(
        children: [
          _parsedRow(Icons.attach_money, 'Amount',
              result.amount != null
                  ? '\$${result.amount!.toStringAsFixed(2)}'
                  : '❌ Not detected',
              result.amount != null),
          const SizedBox(height: 8),
          _parsedRow(Icons.category, 'Category',
              result.matchedCategory?.name ?? '⚠️ Not matched — select below',
              result.matchedCategory != null),
          const SizedBox(height: 8),
          _parsedRow(Icons.notes, 'Description',
              result.description ?? '—', result.description != null),
          const SizedBox(height: 8),
          _parsedRow(Icons.swap_vert, 'Type',
              result.type ?? 'expense', true),
        ],
      ),
    );
  }

  Widget _parsedRow(IconData icon, String label, String value, bool ok) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ok ? Colors.green[700] : Colors.orange[700]),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: ok ? Colors.black87 : Colors.orange[800])),
        ),
      ],
    );
  }

  void _showVoiceConfirmSheet(
      VoiceTransactionResult voiceResult, List<CategoryModel> categories) {
    final amountCtrl = TextEditingController(
        text: voiceResult.amount?.toStringAsFixed(2) ?? '');
    final descCtrl =
    TextEditingController(text: voiceResult.description ?? '');
    DateTime selectedDate = DateTime.now();
    CategoryModel? selectedCategory = voiceResult.matchedCategory;
    String selectedType = voiceResult.type ?? 'expense';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (_, scrollCtrl) => Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.mic,
                              color: AppConstants.primaryGreen),
                          const SizedBox(width: 10),
                          const Text('Confirm Transaction',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 8),

                          // Type toggle
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: ['expense', 'income'].map((t) {
                                final selected = selectedType == t;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setSheetState(() => selectedType = t),
                                    child: AnimatedContainer(
                                      duration:
                                      const Duration(milliseconds: 150),
                                      margin: const EdgeInsets.all(4),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? (t == 'expense'
                                            ? Colors.red
                                            : Colors.green)
                                            : Colors.transparent,
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        t[0].toUpperCase() + t.substring(1),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: selected
                                              ? Colors.white
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Amount
                          TextField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          TextField(
                            controller: descCtrl,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Date picker
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                border:
                                Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[50],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${selectedDate.day.toString().padLeft(2, '0')}/'
                                        '${selectedDate.month.toString().padLeft(2, '0')}/'
                                        '${selectedDate.year}',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.arrow_drop_down,
                                      color: Colors.grey[600]),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Category chips
                          Row(
                            children: [
                              Icon(Icons.category,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text('Category',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700])),
                              if (selectedCategory == null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text('Required',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.red[400],
                                          fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categories.map((cat) {
                              final isSelected =
                                  selectedCategory?.id == cat.id;
                              final color = cat.color;
                              return GestureDetector(
                                onTap: () => setSheetState(() =>
                                selectedCategory =
                                isSelected ? null : cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withOpacity(0.15)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_iconFromName(cat.iconName),
                                          size: 16,
                                          color: isSelected
                                              ? color
                                              : Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text(cat.name,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? color
                                                  : Colors.black87)),
                                      if (isSelected) ...[
                                        const SizedBox(width: 4),
                                        Icon(Icons.check_circle,
                                            size: 14, color: color),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: selectedCategory != null
                                  ? () async {
                                final amount =
                                double.tryParse(amountCtrl.text);
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Please enter a valid amount'),
                                    backgroundColor: Colors.red,
                                  ));
                                  return;
                                }
                                Navigator.pop(context);
                                try {
                                  await _transactionService
                                      .createTransaction(
                                    userId: widget.userId,
                                    walletId: widget.walletId,
                                    categoryId: selectedCategory!.id,
                                    amount: amount,
                                    type: selectedType,
                                    description: descCtrl.text
                                        .trim()
                                        .isEmpty
                                        ? null
                                        : descCtrl.text.trim(),
                                    date: selectedDate,
                                  );
                                  if (!mounted) return;
                                  _showSnackBar(
                                      'Transaction saved!', Colors.green);
                                  if (mounted) setState(() {});
                                } catch (e) {
                                  if (!mounted) return;
                                  _showSnackBar(
                                      'Failed to save: $e', Colors.red);
                                }
                              }
                                  : null,
                              icon: const Icon(Icons.check),
                              label: const Text('Save Transaction',
                                  style: TextStyle(fontSize: 15)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedCategory != null
                                    ? AppConstants.primaryGreen
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Details'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => _showAlertsBottomSheet(),
              ),
              if (_unreadAlertsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    constraints:
                    const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _unreadAlertsCount > 9 ? '9+' : '$_unreadAlertsCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
              icon: const Icon(Icons.edit), onPressed: () => _showEditDialog()),
          IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete()),
        ],
      ),
      body: FutureBuilder<WalletModel>(
        future: _loadWallet(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final wallet = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(wallet),
                  const SizedBox(height: 16),

                  // ── Quick Entry Buttons ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showScanReceiptOptions,
                          icon: const Icon(Icons.document_scanner, size: 18),
                          label: const Text('Scan Receipt'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppConstants.primaryGreen,
                            side: const BorderSide(
                                color: AppConstants.primaryGreen, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _startVoiceTransaction,
                          icon: const Icon(Icons.mic, size: 18),
                          label: const Text('Voice Entry'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                            side: const BorderSide(
                                color: Colors.deepPurple, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // ────────────────────────────────────────────────────────

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionListScreen(
                                  walletId: wallet.id,
                                  userId: widget.userId,
                                ),
                              ),
                            );
                            if (result == true || result == null) setState(() {});
                          },
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('Transactions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BudgetListScreen(
                                  walletId: wallet.id,
                                  userId: widget.userId,
                                ),
                              ),
                            );
                            if (result == true || result == null) setState(() {});
                          },
                          icon: const Icon(Icons.pie_chart),
                          label: const Text('Budgets'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecurringListScreen(
                              walletId: wallet.id,
                              userId: widget.userId,
                            ),
                          ),
                        );
                        if (result == true || result == null) setState(() {});
                      },
                      icon: const Icon(Icons.repeat),
                      label: const Text('Recurring Transactions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SavingGoalsListScreen(
                              walletId: wallet.id,
                              userId: widget.userId,
                            ),
                          ),
                        );
                        if (result == true || result == null) setState(() {});
                      },
                      icon: const Icon(Icons.savings),
                      label: const Text('Saving Goals'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnalyticsScreen(
                              walletId: wallet.id,
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bar_chart),
                      label: const Text('Analytics'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildInfoCard(wallet),
                  const SizedBox(height: 24),

                  if (wallet.type != "personal") _buildMembersSection(wallet),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<WalletModel> _loadWallet() async {
    return await _walletService.getWalletById(widget.walletId);
  }

  Widget _buildBalanceCard(WalletModel wallet) {
    Color walletColor;
    IconData walletIcon;

    switch (wallet.type) {
      case 'family':
        walletColor = AppConstants.familyColor;
        walletIcon = Icons.family_restroom;
        break;
      case 'company':
        walletColor = AppConstants.companyColor;
        walletIcon = Icons.business;
        break;
      default:
        walletColor = AppConstants.personalColor;
        walletIcon = Icons.person;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [walletColor, walletColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: walletColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(walletIcon, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  wallet.name,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            wallet.type.toUpperCase(),
            style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 24),
          const Text('Current Balance',
              style: TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            '${wallet.currency} ${wallet.balance.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(WalletModel wallet) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Created', _formatDate(wallet.createdAt)),
            const Divider(height: 24),
            _buildInfoRow(Icons.update, 'Last Updated', _formatDate(wallet.updatedAt)),
            const Divider(height: 24),
            _buildInfoRow(Icons.people, 'Members',
                '${wallet.memberCount} ${wallet.memberCount == 1 ? 'member' : 'members'}'),
            const Divider(height: 24),
            _buildInfoRow(Icons.monetization_on, 'Currency', wallet.currency),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMembersSection(WalletModel wallet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Members',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showAddMemberDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add'),
              style: TextButton.styleFrom(foregroundColor: AppConstants.primaryGreen),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (wallet.members.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No members yet'),
            ),
          )
        else
          ...wallet.members.map((member) => _buildMemberCard(member, wallet)),
      ],
    );
  }

  Widget _buildMemberCard(WalletMember member, WalletModel wallet) {
    final isCurrentUser = member.userId == widget.userId;
    final canRemove = wallet.memberCount > 1 && !isCurrentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppConstants.primaryGreen,
          child: Text(member.user.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(member.user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (isCurrentUser)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12)),
                child: const Text('You',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.user.email),
            const SizedBox(height: 4),
            Text('Joined ${_formatDate(member.joinedAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: canRemove
            ? IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () => _confirmRemoveMember(member),
        )
            : null,
      ),
    );
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the email address of the person you want to add:'),
            const SizedBox(height: 16),
            TextField(
              controller: _addMemberController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'example@email.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addMemberController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _addMember();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMember() async {
    final email = _addMemberController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Please enter an email', Colors.red);
      return;
    }
    try {
      await _walletService.addMember(widget.walletId, email);
      if (!mounted) return;
      _addMemberController.clear();
      _showSnackBar('Member added successfully!', Colors.green);
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _confirmRemoveMember(WalletMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.user.name} from this wallet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeMember(member);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(WalletMember member) async {
    try {
      await _walletService.removeMember(widget.walletId, member.userId);
      if (!mounted) return;
      _showSnackBar('Member removed', Colors.green);
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showAlertsBottomSheet() async {
    final alerts = await _alertService.getUserAlerts(widget.userId);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Budget Alerts',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (alerts.any((a) => !a.isRead))
                    TextButton(
                      onPressed: () async {
                        for (var alert in alerts.where((a) => !a.isRead)) {
                          await _alertService.markAsRead(alert.id);
                        }
                        Navigator.pop(context);
                        _loadUnreadAlerts();
                        setState(() {});
                      },
                      child: const Text('Mark All Read'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: alerts.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off,
                        size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No alerts',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              )
                  : ListView.builder(
                controller: scrollController,
                itemCount: alerts.length,
                itemBuilder: (context, index) =>
                    _buildAlertCard(alerts[index]),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => _loadUnreadAlerts());
  }

  Widget _buildAlertCard(AlertModel alert) {
    Color color;
    IconData icon;

    switch (alert.alertType) {
      case 'danger':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info;
    }

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await _alertService.deleteAlert(alert.id);
        _loadUnreadAlerts();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: alert.isRead ? Colors.white : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.isRead ? Colors.grey[300]! : color.withOpacity(0.3),
          ),
        ),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(alert.message,
              style: TextStyle(
                  fontWeight:
                  alert.isRead ? FontWeight.normal : FontWeight.bold)),
          subtitle: Text(_formatAlertDate(alert.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          trailing: alert.isRead
              ? null
              : Container(
            width: 8,
            height: 8,
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          onTap: () async {
            if (!alert.isRead) {
              await _alertService.markAsRead(alert.id);
              _loadUnreadAlerts();
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  String _formatAlertDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showEditDialog() async {
    final wallet = await _loadWallet();
    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditWalletScreen(wallet: wallet)),
    );
    if (result == true && mounted) setState(() {});
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wallet'),
        content: const Text(
          'Are you sure you want to delete this wallet? This will also delete all associated budgets and transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteWallet();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWallet() async {
    try {
      await _walletService.deleteWallet(widget.walletId);
      if (!mounted) return;
      _showSnackBar('Wallet deleted', Colors.green);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}