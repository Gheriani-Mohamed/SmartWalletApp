import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/budget_service.dart';
import 'package:smart_wallet_app/services/AlertService.dart';
import 'package:smart_wallet_app/models/BudgetModel.dart';
import 'package:smart_wallet_app/models/AlertModel.dart';
import 'package:smart_wallet_app/utils/constants.dart';

class BudgetDetailsScreen extends StatefulWidget {
  final String budgetId;

  const BudgetDetailsScreen({super.key, required this.budgetId});

  @override
  State<BudgetDetailsScreen> createState() => _BudgetDetailsScreenState();
}

class _BudgetDetailsScreenState extends State<BudgetDetailsScreen> {
  final BudgetService _budgetService = BudgetService();
  final AlertService _alertService = AlertService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Details'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => _syncBudget(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(),
          ),
        ],
      ),
      body: FutureBuilder<BudgetModel>(
        future: _loadBudget(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final budget = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Card
                  _buildProgressCard(budget),
                  const SizedBox(height: 24),

                  // Info Card
                  _buildInfoCard(budget),
                  const SizedBox(height: 24),

                  // Alerts Section
                  const Text(
                    'Alerts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildAlertsSection(budget),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<BudgetModel> _loadBudget() async {
    return await _budgetService.getBudgetById(widget.budgetId);
  }

  Widget _buildProgressCard(BudgetModel budget) {
    final percentage = budget.percentageSpent.clamp(0.0, 100.0);
    final color = budget.statusColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            budget.category?.name ?? 'Budget',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatMonth(budget.month),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),

          // Circular progress
          SizedBox(
            height: 150,
            width: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      budget.isOverspent ? 'EXCEEDED' : 'USED',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Spent / Limit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'Spent',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${budget.currentSpent.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'Limit',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${budget.monthlyLimit.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'Remaining',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${budget.remainingAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BudgetModel budget) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _infoRow(Icons.category, 'Category', budget.category?.name ?? 'Unknown'),
            const Divider(height: 24),
            _infoRow(Icons.account_balance_wallet, 'Wallet', budget.wallet?.name ?? 'Unknown'),
            const Divider(height: 24),
            _infoRow(
              Icons.calendar_today,
              'Created',
              '${budget.createdAt.day}/${budget.createdAt.month}/${budget.createdAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey[600])),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAlertsSection(BudgetModel budget) {
    return FutureBuilder<List<AlertModel>>(
      future: _alertService.getUserAlerts(budget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allAlerts = snapshot.data ?? [];
        final budgetAlerts = allAlerts.where((a) => a.budgetId == budget.id).toList();

        if (budgetAlerts.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No alerts yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }

        return Column(
          children: budgetAlerts.map((alert) => _buildAlertCard(alert)).toList(),
        );
      },
    );
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(alert.message),
        subtitle: Text(
          '${alert.createdAt.day}/${alert.createdAt.month}/${alert.createdAt.year}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: alert.isRead
            ? null
            : Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
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

  Future<void> _syncBudget() async {
    try {
      await _budgetService.syncBudget(widget.budgetId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget synced!'), backgroundColor: Colors.green),
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBudget();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBudget() async {
    try {
      await _budgetService.deleteBudget(widget.budgetId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget deleted'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}