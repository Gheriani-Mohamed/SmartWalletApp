import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/RecurringTransactionService.dart';
import 'package:smart_wallet_app/models/RecurringTransaction.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:smart_wallet_app/screens/ReccuringTransactions/addRecurringScreen.dart';
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

  bool _isCalendarView = false;
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          // Toggle calendar / list view
          IconButton(
            icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
            tooltip: _isCalendarView ? 'List View' : 'Calendar View',
            onPressed: () => setState(() {
              _isCalendarView = !_isCalendarView;
              _selectedDay = null;
            }),
          ),
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

          if (recurring.isEmpty) return _buildEmptyState();

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: _isCalendarView
                ? _buildCalendarView(recurring)
                : _buildListView(recurring),
          );
        },
      ),
      floatingActionButton: _isCalendarView
          ? null
          : FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Recurring'),
      ),
    );
  }

  // ─── Calendar View ──────────────────────────────────────────────────────────

  Widget _buildCalendarView(List<RecurringTransactionModel> recurring) {
    // Build a map of date -> list of recurring transactions due that day
    final Map<String, List<RecurringTransactionModel>> eventMap =
    _buildEventMap(recurring);

    // Selected day events
    final selectedKey = _selectedDay != null ? _dayKey(_selectedDay!) : null;
    final selectedEvents =
    selectedKey != null ? (eventMap[selectedKey] ?? []) : <RecurringTransactionModel>[];

    return Column(
      children: [
        // ── Month navigator ──
        _buildMonthNavigator(),

        // ── Calendar grid ──
        _buildCalendarGrid(eventMap),

        // ── Legend ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _legendDot(Colors.green, 'Income'),
              const SizedBox(width: 16),
              _legendDot(Colors.red, 'Expense'),
              const SizedBox(width: 16),
              _legendDot(Colors.orange, 'Overdue'),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Selected day events or monthly summary ──
        Expanded(
          child: _selectedDay != null
              ? _buildSelectedDayList(selectedEvents)
              : _buildMonthlySummary(recurring, eventMap),
        ),
      ],
    );
  }

  Widget _buildMonthNavigator() {
    return Container(
      color: AppConstants.primaryGreen.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _focusedMonth =
                  DateTime(_focusedMonth.year, _focusedMonth.month - 1);
              _selectedDay = null;
            }),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_focusedMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _focusedMonth =
                  DateTime(_focusedMonth.year, _focusedMonth.month + 1);
              _selectedDay = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
      Map<String, List<RecurringTransactionModel>> eventMap) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // weekday: Mon=1 ... Sun=7, we want Sun=0 for grid offset
    final startOffset = (firstDay.weekday % 7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Day headers
          Row(
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map((d) => Expanded(
              child: Center(
                child: Text(d,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600])),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Day cells
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startOffset) return const SizedBox();
              final day = index - startOffset + 1;
              final date =
              DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final key = _dayKey(date);
              final events = eventMap[key] ?? [];
              final isSelected = _selectedDay != null &&
                  _dayKey(_selectedDay!) == key;
              final isToday = _dayKey(DateTime.now()) == key;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDay = isSelected ? null : date;
                }),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryGreen
                        : isToday
                        ? AppConstants.primaryGreen.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(
                        color: AppConstants.primaryGreen, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (events.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...events.take(3).map((e) => Container(
                              width: 5,
                              height: 5,
                              margin:
                              const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white
                                    : e.isOverdue
                                    ? Colors.orange
                                    : e.type == 'income'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            )),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayList(List<RecurringTransactionModel> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('No transactions on this day',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            DateFormat('EEEE, MMM d').format(_selectedDay!),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (_, i) => _buildRecurringCard(events[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummary(
      List<RecurringTransactionModel> recurring,
      Map<String, List<RecurringTransactionModel>> eventMap) {
    // Count events this month
    final thisMonthKeys = eventMap.keys.where((k) {
      final parts = k.split('-');
      return int.parse(parts[0]) == _focusedMonth.year &&
          int.parse(parts[1]) == _focusedMonth.month;
    }).toList();

    double totalIncome = 0;
    double totalExpense = 0;
    int overdueCount = 0;

    for (final key in thisMonthKeys) {
      for (final r in eventMap[key]!) {
        if (r.type == 'income') {
          totalIncome += r.amount;
        } else {
          totalExpense += r.amount;
        }
        if (r.isOverdue) overdueCount++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap a day to see details',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 12),

          // Summary cards row
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'Income',
                  '\$${totalIncome.toStringAsFixed(2)}',
                  Colors.green,
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  'Expenses',
                  '\$${totalExpense.toStringAsFixed(2)}',
                  Colors.red,
                  Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  'Overdue',
                  '$overdueCount',
                  Colors.orange,
                  Icons.warning_amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Upcoming this month
          const Text('This Month',
              style:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...recurring
              .where((r) {
            final next = r.nextOccurrence;
            return next.year == _focusedMonth.year &&
                next.month == _focusedMonth.month;
          })
              .map((r) => _buildRecurringCard(r))
              .toList(),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color)),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Build map of day key -> recurring transactions due on that day.
  /// Projects every recurring transaction forward across the entire
  /// focused month so daily/weekly/etc. recurrences show on every
  /// applicable day, not just the next single occurrence.
  Map<String, List<RecurringTransactionModel>> _buildEventMap(
      List<RecurringTransactionModel> recurring) {
    final map = <String, List<RecurringTransactionModel>>{};
    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final monthEnd = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    for (final r in recurring) {
      // Include overdue today
      if (r.isOverdue) {
        final todayKey = _dayKey(DateTime.now());
        map.putIfAbsent(todayKey, () => []).add(r);
      }

      // Start projecting from nextOccurrence or monthStart
      DateTime cursor = r.nextOccurrence.isBefore(monthStart) ? monthStart : r.nextOccurrence;

      while (!cursor.isAfter(monthEnd)) {
        // Respect endDate
        if (r.endDate != null && cursor.isAfter(r.endDate!)) break;

        final key = _dayKey(cursor);
        if (!map.containsKey(key) || !map[key]!.any((e) => e.id == r.id)) {
          map.putIfAbsent(key, () => []).add(r);
        }

        cursor = _advanceByFrequency(cursor, r);
      }
    }

    return map;
  }

  /// Advance a date by the frequency of a recurring transaction
  DateTime _advanceByFrequency(DateTime date, RecurringTransactionModel r) {
    switch (r.frequency.toLowerCase()) {
      case 'daily':
        return date.add(const Duration(days: 1));
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'biweekly':
        return date.add(const Duration(days: 14));
      case 'monthly':
        final nextMonth = DateTime(date.year, date.month + 1, 1);
        final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        return DateTime(nextMonth.year, nextMonth.month, date.day > lastDay ? lastDay : date.day);
      case 'yearly':
        return DateTime(date.year + 1, date.month, date.day);
      default:
        return date.add(const Duration(days: 1));
    }
  }

  // ─── List View ──────────────────────────────────────────────────────────────

  Widget _buildListView(List<RecurringTransactionModel> recurring) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recurring.length,
      itemBuilder: (context, index) =>
          _buildRecurringCard(recurring[index]),
    );
  }

  // ─── Shared Card ────────────────────────────────────────────────────────────

  Widget _buildRecurringCard(RecurringTransactionModel recurring) {
    final isIncome = recurring.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    final nextDate = recurring.nextOccurrence;
    final isOverdue = recurring.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showRecurringDetails(recurring),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.repeat, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recurring.description ?? 'Recurring ${recurring.type}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
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
                            color:
                            isOverdue ? Colors.orange : Colors.grey[600],
                            fontWeight: isOverdue
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'generate', child: Text('Generate Now')),
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

  // ─── Detail Sheet ────────────────────────────────────────────────────────────

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
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          recurring.type.toUpperCase(),
                          style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _detailRow('Amount',
                  '\$${recurring.amount.toStringAsFixed(2)}', color),
              const Divider(height: 24),
              _detailRow('Frequency', recurring.frequencyDisplay,
                  Colors.grey[800]!),
              const Divider(height: 24),
              _detailRow(
                  'Start Date',
                  DateFormat('MMM dd, yyyy – HH:mm')
                      .format(recurring.startDate),
                  Colors.grey[800]!),
              const Divider(height: 24),
              _detailRow(
                  'End Date',
                  recurring.endDate != null
                      ? DateFormat('MMM dd, yyyy').format(recurring.endDate!)
                      : 'No end date',
                  Colors.grey[800]!),
              const Divider(height: 24),
              _detailRow(
                  'Last Generated',
                  DateFormat('MMM dd, yyyy').format(recurring.lastGenerated),
                  Colors.grey[800]!),
              const Divider(height: 24),
              _detailRow(
                'Next Generation',
                recurring.isOverdue
                    ? 'OVERDUE - Generate now!'
                    : DateFormat('MMM dd, yyyy – HH:mm')
                    .format(recurring.nextOccurrence),
                recurring.isOverdue ? Colors.orange : Colors.grey[800]!,
              ),
              const Divider(height: 24),
              _detailRow(
                  'Status',
                  recurring.isActive ? 'Active' : 'Inactive',
                  recurring.isActive ? Colors.green : Colors.red),
              const SizedBox(height: 32),
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
        Text(label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor)),
      ],
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.repeat, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No recurring transactions',
              style: TextStyle(fontSize: 20, color: Colors.grey[600])),
          const SizedBox(height: 8),
          const Text('Set up automatic recurring payments'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAdd(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryGreen,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create Recurring'),
          ),
        ],
      ),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _generateNow(RecurringTransactionModel recurring) async {
    try {
      final result = await _service.generateTransactions(recurring.id);
      if (mounted) {
        final count = result['transactions']?.length ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Generated $count transaction(s)!'),
          backgroundColor: Colors.green,
        ));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _generateAll() async {
    try {
      final result =
      await _service.generateAllUserTransactions(widget.userId);
      if (mounted) {
        final count = result['totalGenerated'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Generated $count transaction(s)!'),
          backgroundColor: Colors.green,
        ));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _confirmDelete(RecurringTransactionModel recurring) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Transaction'),
        content: const Text(
            'Are you sure? This will stop future automatic transactions.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Recurring transaction deleted'),
          backgroundColor: Colors.green,
        ));
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
        builder: (context) => AddRecurringScreen(
          walletId: widget.walletId,
          userId: widget.userId,
        ),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<List<RecurringTransactionModel>> _loadRecurring() async {
    return await _service.getWalletRecurring(widget.walletId);
  }
}