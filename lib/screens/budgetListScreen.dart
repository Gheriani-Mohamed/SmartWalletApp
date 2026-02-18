import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/budget_service.dart';
import 'package:smart_wallet_app/models/BudgetModel.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:smart_wallet_app/screens/addBudgetScreen.dart';
import 'package:smart_wallet_app/screens/BudgetDetailsScreen.dart';

class BudgetListScreen extends StatefulWidget {
  final String walletId;
  final String userId;

  const BudgetListScreen({
    super.key,
    required this.walletId,
    required this.userId,
  });

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  final BudgetService _budgetService = BudgetService();
  String _selectedMonth = BudgetService.getCurrentMonth();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => _syncBudgets(),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectMonth(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.all(16),
            color: AppConstants.primaryGreen.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  _formatMonth(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          // Budgets list
          Expanded(
            child: FutureBuilder<List<BudgetModel>>(
              future: _loadBudgets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final budgets = snapshot.data ?? [];

                if (budgets.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      return _buildBudgetCard(budgets[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Budget'),
      ),
    );
  }

  Future<List<BudgetModel>> _loadBudgets() async {
    // Get budgets for THIS WALLET in selected month
    return await _budgetService.getWalletMonthlyBudgets(widget.walletId, _selectedMonth);
  }

  Widget _buildBudgetCard(BudgetModel budget) {
    final percentage = budget.percentageSpent.clamp(0.0, 100.0);
    final color = budget.statusColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetails(budget),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      budget.category?.name ?? 'Unknown Category',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(budget),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 8),

              // Spent / Limit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${budget.currentSpent.toStringAsFixed(2)} spent',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'of \$${budget.monthlyLimit.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Percentage
              Text(
                '${percentage.toStringAsFixed(1)}% used',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BudgetModel budget) {
    String text;
    Color color;

    if (budget.isOverspent) {
      text = 'EXCEEDED';
      color = Colors.red;
    } else if (budget.isNearLimit) {
      text = 'CRITICAL';
      color = Colors.orange;
    } else if (budget.isAtWarning) {
      text = 'WARNING';
      color = Colors.amber;
    } else {
      text = 'ON TRACK';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No budgets for ${_formatMonth(_selectedMonth)}',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text('Create a budget to track your spending'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAdd(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
          ),
        ],
      ),
    );
  }

  String _formatMonth(String month) {
    final parts = month.split('-');
    final year = parts[0];
    final monthNum = int.parse(parts[1]);

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return '${months[monthNum - 1]} $year';
  }

  void _changeMonth(int delta) {
    final parts = _selectedMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    final newDate = DateTime(year, month + delta);
    setState(() {
      _selectedMonth = '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _selectMonth() async {
    final parts = _selectedMonth.split('-');
    final initialDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _syncBudgets() async {
    try {
      await _budgetService.syncAllBudgets(widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budgets synced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBudgetScreen(
          walletId: widget.walletId,
          userId: widget.userId,
          month: _selectedMonth,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _navigateToDetails(BudgetModel budget) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetDetailsScreen(budgetId: budget.id),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }
}