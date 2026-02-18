import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/RecurringTransactionService.dart';
import 'package:smart_wallet_app/models/RecurringTransaction.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:smart_wallet_app/screens/addRecurringScreen.dart';
import 'package:intl/intl.dart';

class RecurringListScreen extends StatefulWidget {
  final String walletId;
  final String userId;

  const RecurringListScreen({
    super.key,
    required this.walletId,
    required this.userId,
  });

  @override
  State<RecurringListScreen> createState() => _RecurringListScreenState();
}

class _RecurringListScreenState extends State<RecurringListScreen> {
  final RecurringTransactionService _service = RecurringTransactionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => _generateAll(),
          ),
        ],
      ),
      body: FutureBuilder<List<RecurringTransactionModel>>(
        future: _loadRecurring(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final recurring = snapshot.data ?? [];

          if (recurring.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recurring.length,
              itemBuilder: (context, index) {
                return _buildRecurringCard(recurring[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Recurring'),
      ),
    );
  }

  Future<List<RecurringTransactionModel>> _loadRecurring() async {
    return await _service.getWalletRecurring(widget.walletId);
  }

  Widget _buildRecurringCard(RecurringTransactionModel recurring) {
    final isIncome = recurring.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    final nextDate = recurring.nextOccurrence;
    final isOverdue = recurring.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.repeat,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          recurring.description ?? 'Recurring ${recurring.type}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '\$${recurring.amount.toStringAsFixed(2)} • ${recurring.frequencyDisplay}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isOverdue ? Icons.warning : Icons.schedule,
                  size: 14,
                  color: isOverdue ? Colors.orange : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  isOverdue
                      ? 'Overdue! Generate now'
                      : 'Next: ${DateFormat('MMM dd').format(nextDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? Colors.orange : Colors.grey[600],
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'generate', child: Text('Generate Now')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) {
            if (value == 'generate') {
              _generateNow(recurring);
            } else if (value == 'delete') {
              _confirmDelete(recurring);
            }
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
          Icon(Icons.repeat, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No recurring transactions',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text('Set up automatic recurring payments'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAdd(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create Recurring'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateNow(RecurringTransactionModel recurring) async {
    try {
      final result = await _service.generateTransactions(recurring.id);

      if (mounted) {
        final count = result['transactions']?.length ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated $count transaction(s)!'),
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

  Future<void> _generateAll() async {
    try {
      final result = await _service.generateAllUserTransactions(widget.userId);

      if (mounted) {
        final count = result['totalGenerated'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated $count transaction(s)!'),
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

  void _confirmDelete(RecurringTransactionModel recurring) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Transaction'),
        content: const Text('Are you sure? This will stop future automatic transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteRecurring(recurring);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecurring(RecurringTransactionModel recurring) async {
    try {
      await _service.deleteRecurring(recurring.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recurring transaction deleted'), backgroundColor: Colors.green),
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
        builder: (context) => AddRecurringScreen(
          walletId: widget.walletId,
          userId: widget.userId,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }
}