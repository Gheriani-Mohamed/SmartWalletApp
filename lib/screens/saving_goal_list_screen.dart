import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/savingGoals_service.dart';
import 'package:smart_wallet_app/models/savingGoalsModel.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:smart_wallet_app/screens/add_saving_goal_screen.dart';
import 'package:smart_wallet_app/screens/saving_goal_details_screen.dart';

class SavingGoalsListScreen extends StatefulWidget {
  final String walletId;
  final String userId;

  const SavingGoalsListScreen({
    super.key,
    required this.walletId,
    required this.userId,
  });

  @override
  State<SavingGoalsListScreen> createState() => _SavingGoalsListScreenState();
}

class _SavingGoalsListScreenState extends State<SavingGoalsListScreen> {
  final SavingGoalService _service = SavingGoalService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saving Goals'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<SavingGoalModel>>(
        future: _service.getWalletGoals(widget.walletId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final goals = snapshot.data ?? [];

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No saving goals yet', style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  const Text('Create a goal to start saving'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAdd(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Goal'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) => _buildGoalCard(goals[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _buildGoalCard(SavingGoalModel goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetails(goal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (goal.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('✅ Completed', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal.progressPercentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(goal.progressColor),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${goal.currentAmount.toStringAsFixed(2)} saved', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  Text('of \$${goal.targetAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${goal.progressPercentage.toStringAsFixed(1)}% complete',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: goal.progressColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSavingGoalScreen(
          walletId: widget.walletId,
          userId: widget.userId,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _navigateToDetails(SavingGoalModel goal) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavingGoalDetailsScreen(goalId: goal.id),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }
}