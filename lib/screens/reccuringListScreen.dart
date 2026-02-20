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
      child: InkWell(
        onTap: () => _showRecurringDetails(recurring), // 🔥 Show details on tap
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
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
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recurring.description ?? 'Recurring ${recurring.type}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
              ),

              // Menu button
              PopupMenuButton(
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
            ],
          ),
        ),
      ),
    );
  }

  void _showRecurringDetails(RecurringTransactionModel recurring) {
    final isIncome = recurring.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.repeat, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recurring.description ?? 'Recurring Transaction',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          recurring.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Amount
              _detailRow('Amount', '\$${recurring.amount.toStringAsFixed(2)}', color),
              const Divider(height: 24),

              // Frequency
              _detailRow('Frequency', recurring.frequencyDisplay, Colors.grey[800]!),
              const Divider(height: 24),

              // Start Date
              _detailRow(
                'Start Date',
                DateFormat('MMM dd, yyyy – HH:mm')
                    .format(recurring.startDate),
                Colors.grey[800]!,
              ),
              const Divider(height: 24),

              // End Date
              _detailRow(
                'End Date',
                recurring.endDate != null
                    ? DateFormat('MMM dd, yyyy').format(recurring.endDate!)
                    : 'No end date',
                Colors.grey[800]!,
              ),
              const Divider(height: 24),

              // Last Generated
              _detailRow(
                'Last Generated',
                DateFormat('MMM dd, yyyy').format(recurring.lastGenerated),
                Colors.grey[800]!,
              ),
              const Divider(height: 24),

              // Next Occurrence
              _detailRow(
                'Next Generation',
                recurring.isOverdue
                    ? 'OVERDUE - Generate now!'
                    : DateFormat('MMM dd, yyyy – HH:mm').format(recurring.nextOccurrence),
                recurring.isOverdue ? Colors.orange : Colors.grey[800]!,
              ),
              const Divider(height: 24),

              // Status
              _detailRow(
                'Status',
                recurring.isActive ? 'Active' : 'Inactive',
                recurring.isActive ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _generateNow(recurring);
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('Generate Now'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(recurring);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
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