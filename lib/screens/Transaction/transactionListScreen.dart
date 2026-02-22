import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/transaction_service.dart';
import 'package:smart_wallet_app/services/Category_service.dart';
import 'package:smart_wallet_app/models/transaction_model.dart';
import 'package:smart_wallet_app/models/CategoryModel.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:smart_wallet_app/screens/Transaction/addTransactionScreen.dart';
import 'package:intl/intl.dart';

class TransactionListScreen extends StatefulWidget {
  final String walletId;
  final String userId;

  const TransactionListScreen({
    super.key,
    required this.walletId,
    required this.userId,
  });

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();

  // ─── Filter State ────────────────────────────────────────────────────────────
  String _filterType = 'all'; // all, income, expense
  CategoryModel? _filterCategory;
  DateTime? _filterMonth; // year+month only
  double? _amountFrom;
  double? _amountTo;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  List<CategoryModel> _categories = [];
  bool _categoriesLoaded = false;

  // ─── Active filter count ─────────────────────────────────────────────────────
  int get _activeFilterCount {
    int count = 0;
    if (_filterType != 'all') count++;
    if (_filterCategory != null) count++;
    if (_filterMonth != null) count++;
    if (_amountFrom != null || _amountTo != null) count++;
    if (_dateFrom != null || _dateTo != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _categoryService.getAllCategories();
      if (mounted) setState(() { _categories = cats; _categoriesLoaded = true; });
    } catch (_) {
      if (mounted) setState(() => _categoriesLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          // Filter button with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: _showFilterSheet,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filter chips
          if (_activeFilterCount > 0) _buildActiveFilterChips(),

          // Stats Summary Card
          FutureBuilder<Map<String, dynamic>>(
            future: _transactionService.getWalletStats(widget.walletId),
            builder: (context, snapshot) {
              if (snapshot.hasData) return _buildStatsCard(snapshot.data!);
              return const SizedBox.shrink();
            },
          ),

          // Transactions List
          Expanded(
            child: FutureBuilder<List<TransactionModel>>(
              future: _loadTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final all = snapshot.data ?? [];
                final filtered = _applyFilters(all);

                if (filtered.isEmpty) return _buildEmptyState();

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _buildTransactionCard(filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Transaction'),
      ),
    );
  }

  // ─── Filtering ───────────────────────────────────────────────────────────────

  Future<List<TransactionModel>> _loadTransactions() async {
    return await _transactionService.getWalletTransactions(widget.walletId);
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> transactions) {
    return transactions.where((t) {
      // Type filter
      if (_filterType != 'all' && t.type != _filterType) return false;

      // Category filter
      if (_filterCategory != null && t.category?.id != _filterCategory!.id) return false;

      // Month filter
      if (_filterMonth != null) {
        if (t.date.year != _filterMonth!.year ||
            t.date.month != _filterMonth!.month) return false;
      }

      // Amount range
      if (_amountFrom != null && t.amount < _amountFrom!) return false;
      if (_amountTo != null && t.amount > _amountTo!) return false;

      // Date range
      if (_dateFrom != null &&
          t.date.isBefore(DateTime(_dateFrom!.year, _dateFrom!.month, _dateFrom!.day))) {
        return false;
      }
      if (_dateTo != null &&
          t.date.isAfter(DateTime(_dateTo!.year, _dateTo!.month, _dateTo!.day, 23, 59, 59))) {
        return false;
      }

      return true;
    }).toList();
  }

  // ─── Filter Sheet ─────────────────────────────────────────────────────────────

  void _showFilterSheet() {
    // Local copies for editing before applying
    String tempType = _filterType;
    CategoryModel? tempCategory = _filterCategory;
    DateTime? tempMonth = _filterMonth;
    final amountFromCtrl = TextEditingController(text: _amountFrom?.toString() ?? '');
    final amountToCtrl = TextEditingController(text: _amountTo?.toString() ?? '');
    DateTime? tempDateFrom = _dateFrom;
    DateTime? tempDateTo = _dateTo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheet) => DraggableScrollableSheet(
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
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.tune, color: AppConstants.primaryGreen),
                    const SizedBox(width: 8),
                    const Text('Filter Transactions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setSheet(() {
                          tempType = 'all';
                          tempCategory = null;
                          tempMonth = null;
                          amountFromCtrl.clear();
                          amountToCtrl.clear();
                          tempDateFrom = null;
                          tempDateTo = null;
                        });
                      },
                      child: const Text('Reset All',
                          style: TextStyle(color: Colors.red)),
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

                    // ── Type ──────────────────────────────────────────────
                    _filterSection('Transaction Type', Icons.swap_vert,
                      child: Row(
                        children: ['all', 'income', 'expense'].map((t) {
                          final selected = tempType == t;
                          final color = t == 'income'
                              ? Colors.green
                              : t == 'expense'
                              ? Colors.red
                              : AppConstants.primaryGreen;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setSheet(() => tempType = t),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? color.withOpacity(0.15)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected ? color : Colors.grey.shade300,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  t[0].toUpperCase() + t.substring(1),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: selected ? color : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // ── Category ──────────────────────────────────────────
                    _filterSection('Category', Icons.category,
                      child: !_categoriesLoaded
                          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // "All" chip
                          GestureDetector(
                            onTap: () => setSheet(() => tempCategory = null),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: tempCategory == null
                                    ? AppConstants.primaryGreen.withOpacity(0.15)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: tempCategory == null
                                      ? AppConstants.primaryGreen
                                      : Colors.grey.shade300,
                                  width: tempCategory == null ? 2 : 1,
                                ),
                              ),
                              child: Text('All',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: tempCategory == null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: tempCategory == null
                                        ? AppConstants.primaryGreen
                                        : Colors.black87,
                                  )),
                            ),
                          ),
                          ..._categories.map((cat) {
                            final selected = tempCategory?.id == cat.id;
                            final color = cat.color;
                            return GestureDetector(
                              onTap: () => setSheet(() =>
                              tempCategory = selected ? null : cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? color.withOpacity(0.15)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? color
                                        : Colors.grey.shade300,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Text(cat.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: selected
                                          ? color
                                          : Colors.black87,
                                    )),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // ── Month ─────────────────────────────────────────────
                    _filterSection('Month', Icons.calendar_month,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempMonth ?? now,
                            firstDate: DateTime(2020),
                            lastDate: now,
                            helpText: 'Select Month',
                            // Restrict to month picker feel
                          );
                          if (picked != null) {
                            setSheet(() => tempMonth =
                                DateTime(picked.year, picked.month));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: tempMonth != null
                                  ? AppConstants.primaryGreen
                                  : Colors.grey.shade300,
                              width: tempMonth != null ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: tempMonth != null
                                ? AppConstants.primaryGreen.withOpacity(0.05)
                                : Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 18,
                                  color: tempMonth != null
                                      ? AppConstants.primaryGreen
                                      : Colors.grey[500]),
                              const SizedBox(width: 10),
                              Text(
                                tempMonth != null
                                    ? DateFormat('MMMM yyyy').format(tempMonth!)
                                    : 'All months',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: tempMonth != null
                                      ? AppConstants.primaryGreen
                                      : Colors.grey[600],
                                  fontWeight: tempMonth != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (tempMonth != null)
                                GestureDetector(
                                  onTap: () =>
                                      setSheet(() => tempMonth = null),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.grey),
                                )
                              else
                                Icon(Icons.arrow_drop_down,
                                    color: Colors.grey[500]),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Amount Range ──────────────────────────────────────
                    _filterSection('Amount Range', Icons.attach_money,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: amountFromCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: InputDecoration(
                                labelText: 'From',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('—',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: amountToCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: InputDecoration(
                                labelText: 'To',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Date Range ────────────────────────────────────────
                    _filterSection('Date Range', Icons.date_range,
                      child: Row(
                        children: [
                          Expanded(
                            child: _datePicker(
                              label: 'From',
                              value: tempDateFrom,
                              onPicked: (d) =>
                                  setSheet(() => tempDateFrom = d),
                              onCleared: () =>
                                  setSheet(() => tempDateFrom = null),
                              lastDate: tempDateTo ?? DateTime.now(),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('—',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey)),
                          ),
                          Expanded(
                            child: _datePicker(
                              label: 'To',
                              value: tempDateTo,
                              onPicked: (d) =>
                                  setSheet(() => tempDateTo = d),
                              onCleared: () =>
                                  setSheet(() => tempDateTo = null),
                              firstDate: tempDateFrom,
                              lastDate: DateTime.now(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filterType = tempType;
                            _filterCategory = tempCategory;
                            _filterMonth = tempMonth;
                            _amountFrom = double.tryParse(amountFromCtrl.text);
                            _amountTo = double.tryParse(amountToCtrl.text);
                            _dateFrom = tempDateFrom;
                            _dateTo = tempDateTo;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Apply Filters',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterSection(String title, IconData icon, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
          ],
        ),
        const SizedBox(height: 10),
        child,
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? value,
    required void Function(DateTime) onPicked,
    required void Function() onCleared,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime.now(),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: value != null
                ? AppConstants.primaryGreen
                : Colors.grey.shade300,
            width: value != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: value != null
              ? AppConstants.primaryGreen.withOpacity(0.05)
              : Colors.grey[50],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null
                    ? DateFormat('dd MMM yy').format(value)
                    : label,
                style: TextStyle(
                  fontSize: 12,
                  color: value != null
                      ? AppConstants.primaryGreen
                      : Colors.grey[500],
                  fontWeight: value != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onCleared,
                child: const Icon(Icons.close, size: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Active Filter Chips ──────────────────────────────────────────────────────

  Widget _buildActiveFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Clear all chip
          ActionChip(
            label: const Text('Clear all'),
            avatar: const Icon(Icons.close, size: 14),
            backgroundColor: Colors.red[50],
            labelStyle: const TextStyle(color: Colors.red, fontSize: 12),
            onPressed: () => setState(() {
              _filterType = 'all';
              _filterCategory = null;
              _filterMonth = null;
              _amountFrom = null;
              _amountTo = null;
              _dateFrom = null;
              _dateTo = null;
            }),
          ),
          const SizedBox(width: 8),
          if (_filterType != 'all')
            _activeChip(_filterType, () => setState(() => _filterType = 'all')),
          if (_filterCategory != null)
            _activeChip(_filterCategory!.name,
                    () => setState(() => _filterCategory = null)),
          if (_filterMonth != null)
            _activeChip(DateFormat('MMM yyyy').format(_filterMonth!),
                    () => setState(() => _filterMonth = null)),
          if (_amountFrom != null || _amountTo != null)
            _activeChip(
              '\$${_amountFrom?.toStringAsFixed(0) ?? '0'} — \$${_amountTo?.toStringAsFixed(0) ?? '∞'}',
                  () => setState(() { _amountFrom = null; _amountTo = null; }),
            ),
          if (_dateFrom != null || _dateTo != null)
            _activeChip(
              '${_dateFrom != null ? DateFormat('dd MMM').format(_dateFrom!) : '...'} → ${_dateTo != null ? DateFormat('dd MMM').format(_dateTo!) : '...'}',
                  () => setState(() { _dateFrom = null; _dateTo = null; }),
            ),
        ],
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onRemove,
        backgroundColor: AppConstants.primaryGreen.withOpacity(0.1),
        deleteIconColor: AppConstants.primaryGreen,
        labelStyle: const TextStyle(color: AppConstants.primaryGreen),
        side: BorderSide(color: AppConstants.primaryGreen.withOpacity(0.3)),
      ),
    );
  }

  // ─── Stats Card ───────────────────────────────────────────────────────────────

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    final income = (stats['totalIncome'] ?? 0).toDouble();
    final expense = (stats['totalExpense'] ?? 0).toDouble();
    final balance = (stats['balance'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.primaryGreen, AppConstants.darkGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Income', income, Icons.arrow_upward, Colors.greenAccent),
              _buildStatItem('Expense', expense, Icons.arrow_downward, Colors.redAccent),
            ],
          ),
          const Divider(color: Colors.white30, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Balance: ',
                  style: TextStyle(fontSize: 16, color: Colors.white70)),
              Text('\$${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, double amount, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 4),
        Text('\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }

  // ─── Transaction Card ─────────────────────────────────────────────────────────

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                transaction.category?.name ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null &&
                transaction.description!.isNotEmpty)
              Text(transaction.description!),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(transaction.date),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () => _showTransactionDetails(transaction),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) {
            if (value == 'delete') _confirmDelete(transaction);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _activeFilterCount > 0
                ? Icons.filter_list_off
                : Icons.receipt_long,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _activeFilterCount > 0
                ? 'No transactions match your filters'
                : 'No transactions yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          if (_activeFilterCount > 0) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() {
                _filterType = 'all';
                _filterCategory = null;
                _filterMonth = null;
                _amountFrom = null;
                _amountTo = null;
                _dateFrom = null;
                _dateTo = null;
              }),
              child: const Text('Clear all filters'),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Detail / Delete ──────────────────────────────────────────────────────────

  void _showTransactionDetails(TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.category?.name ?? 'Transaction',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _detailRow('Amount',
                '\$${transaction.amount.toStringAsFixed(2)}'),
            _detailRow('Type', transaction.type.toUpperCase()),
            _detailRow('Date',
                DateFormat('MMM dd, yyyy').format(transaction.date)),
            if (transaction.description != null)
              _detailRow('Description', transaction.description!),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _confirmDelete(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
            'Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTransaction(transaction);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    try {
      await _transactionService.deleteTransaction(transaction.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Transaction deleted'),
            backgroundColor: Colors.green));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          walletId: widget.walletId,
          userId: widget.userId,
        ),
      ),
    );
    if (result == true) setState(() {});
  }
}