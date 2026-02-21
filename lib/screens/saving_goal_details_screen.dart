import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/savingGoals_service.dart';
import 'package:smart_wallet_app/models/savingGoalsModel.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:intl/intl.dart';

class SavingGoalDetailsScreen extends StatefulWidget {
  final String goalId;

  const SavingGoalDetailsScreen({super.key, required this.goalId});

  @override
  State<SavingGoalDetailsScreen> createState() => _SavingGoalDetailsScreenState();
}

class _SavingGoalDetailsScreenState extends State<SavingGoalDetailsScreen> {
  final SavingGoalService _service = SavingGoalService();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete()),
        ],
      ),
      body: FutureBuilder<SavingGoalModel>(
        future: _service.getGoalById(widget.goalId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final goal = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProgressCard(goal),
                  const SizedBox(height: 24),
                  _buildDetailsCard(goal),
                  const SizedBox(height: 24),
                  _buildActionButtons(goal),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard(SavingGoalModel goal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [goal.progressColor, goal.progressColor.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: goal.progressColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(goal.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: goal.progressPercentage / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Center(child: Text('${goal.progressPercentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('\$${goal.currentAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('of \$${goal.targetAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
          const SizedBox(height: 16),
          if (!goal.isCompleted)
            Text('\$${goal.remainingAmount.toStringAsFixed(2)} remaining', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
          if (goal.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Text('🎉 Goal Completed!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(SavingGoalModel goal) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _detailRow('Start Date', DateFormat('MMM dd, yyyy').format(goal.startDate)),
            const Divider(height: 24),
            _detailRow('End Date', goal.endDate != null ? DateFormat('MMM dd, yyyy').format(goal.endDate!) : 'No end date'),
            const Divider(height: 24),
            _detailRow('Status', goal.isCompleted ? 'Completed ✅' : 'In Progress 🎯'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButtons(SavingGoalModel goal) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showContributeDialog(goal),
            icon: const Icon(Icons.add),
            label: const Text('Add Money'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: goal.currentAmount > 0 ? () => _showWithdrawDialog(goal) : null,
            icon: const Icon(Icons.remove),
            label: const Text('Withdraw'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  void _showContributeDialog(SavingGoalModel goal) {
    _amountController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: \$${goal.currentAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ ', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(_amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount'), backgroundColor: Colors.red));
                return;
              }
              Navigator.pop(dialogContext);
              await _service.addContribution(goal.id, amount);

              if (!mounted) return;

              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added \$${amount.toStringAsFixed(2)}!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(SavingGoalModel goal) {
    _amountController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available: \$${goal.currentAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ ', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(_amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount'), backgroundColor: Colors.red));
                return;
              }
              if (amount > goal.currentAmount) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient funds'), backgroundColor: Colors.red));
                return;
              }
              Navigator.pop(context);
              await _service.withdraw(goal.id, amount);
              setState(() {});
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Withdrew \$${amount.toStringAsFixed(2)}'), backgroundColor: Colors.orange));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _service.deleteGoal(widget.goalId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal deleted'), backgroundColor: Colors.red));
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}