import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_wallet_app/services/budget_service.dart';
import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:smart_wallet_app/models/BudgetModel.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final BudgetService _budgetService = BudgetService();
  final ApiService _apiService = ApiService();

  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String _status = 'Ready to test';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test Screen'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: AppConstants.primaryGreen.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Test Buttons
            const Text(
              'Test Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Test Connection Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testConnection,
                icon: const Icon(Icons.wifi),
                label: const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Setup Test Data Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _setupTestData,
                icon: const Icon(Icons.settings),
                label: const Text('Setup Test User & Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Create Budget Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createTestBudget,
                icon: const Icon(Icons.add),
                label: const Text('Create Test Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Get Budgets Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _getBudgets,
                icon: const Icon(Icons.download),
                label: const Text('Get All Budgets'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Budgets List
            const Text(
              'Budgets from Database',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Loading or List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _budgets.isEmpty
                  ? const Center(
                child: Text('No budgets yet. Create one!'),
              )
                  : ListView.builder(
                itemCount: _budgets.length,
                itemBuilder: (context, index) {
                  final budget = _budgets[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppConstants.primaryGreen,
                        child: Text(
                          budget.categoryId[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(budget.categoryId),
                      subtitle: Text(
                        'Limit: \$${budget.monthlyLimit} | Spent: \$${budget.currentSpent}',
                      ),
                      trailing: Text(
                        '${budget.percentageSpent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: budget.isOverspent
                              ? Colors.red
                              : AppConstants.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Test backend connection
  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
    });

    try {
      // bjeeeh rabbii emchii
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/health'),
      );

      if (!mounted) return;

      setState(() {
        _status = '✅ Backend Connected!\nStatus: ${response.statusCode}';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backend connected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = '❌ Connection failed!\n$e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Setup test user and wallet
  Future<void> _setupTestData() async {
    setState(() {
      _isLoading = true;
      _status = 'Setting up test data...';
    });

    try {
      final response = await _apiService.post('/setup/create', {});

      if (!mounted) return;

      setState(() {
        _status = '✅ Test data created!\nUser: ${response['user']['email']}\nWallet: ${response['wallet']['name']}';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test user and wallet created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = '❌ Setup failed!\n$e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Create a test budget
  Future<void> _createTestBudget() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating budget...';
    });

    try {
      final response = await _apiService.post('/budgets', {
        'userId': 'user123',
        'walletId': 'wallet123',
        'categoryId': 'c58708fc-b25c-4d68-b4f4-61d497710154',
        'monthlyLimit': 500.0,
        'month': _getCurrentMonth(),
      });

      if (!mounted) return;

      setState(() {
        _status = '✅ Budget created!\nID: ${response['id']}';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh list
      await _getBudgets();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = '❌ Failed to create budget!\n$e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get all budgets
  Future<void> _getBudgets() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _status = 'Fetching budgets...';
    });

    try {
      final budgets = await _budgetService.getUserBudgets('user123');

      if (!mounted) return;

      setState(() {
        _budgets = budgets;
        _status = '✅ Found ${budgets.length} budget(s)';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${budgets.length} budgets'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = '❌ Failed to get budgets!\n$e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}