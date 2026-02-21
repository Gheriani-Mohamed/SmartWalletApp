import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/savingGoals_service.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:intl/intl.dart';

class AddSavingGoalScreen extends StatefulWidget {
  final String walletId;
  final String userId;

  const AddSavingGoalScreen({super.key, required this.walletId, required this.userId});

  @override
  State<AddSavingGoalScreen> createState() => _AddSavingGoalScreenState();
}

class _AddSavingGoalScreenState extends State<AddSavingGoalScreen> {
  final SavingGoalService _service = SavingGoalService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _hasEndDate = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Saving Goal'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  hintText: 'e.g., Vacation Fund',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  hintText: '0.00',
                  prefixText: '\$ ',
                  prefixIcon: const Icon(Icons.savings),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter target amount';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  if (double.parse(v) <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _pickStartDate(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Start Date', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            Text(DateFormat('MMM dd, yyyy').format(_startDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Set End Date'),
                subtitle: _hasEndDate && _endDate != null ? Text(DateFormat('MMM dd, yyyy').format(_endDate!)) : const Text('No end date'),
                value: _hasEndDate,
                onChanged: (v) {
                  setState(() {
                    _hasEndDate = v;
                    if (v && _endDate == null) _endDate = _startDate.add(const Duration(days: 365));
                  });
                  if (v) _pickEndDate();
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text('Create Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
    if (date != null) setState(() => _startDate = date);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(context: context, initialDate: _endDate ?? _startDate.add(const Duration(days: 365)), firstDate: _startDate, lastDate: DateTime(2030));
    if (date != null) setState(() => _endDate = date);
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _service.createGoal(
        userId: widget.userId,
        walletId: widget.walletId,
        title: _titleController.text.trim(),
        targetAmount: double.parse(_targetController.text),
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal created!'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}