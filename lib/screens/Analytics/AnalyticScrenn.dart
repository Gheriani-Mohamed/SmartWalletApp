import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/AnalyticsService.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  final String walletId;
  final String userId;

  const AnalyticsScreen({super.key, required this.walletId, required this.userId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _service = AnalyticsService();
  String _selectedPeriod = 'month';

  final List<Map<String, String>> _periods = [
    {'value': 'day', 'label': 'Today'},
    {'value': 'week', 'label': 'Week'},
    {'value': 'month', 'label': 'Month'},
    {'value': 'year', 'label': 'Year'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildCategoryPieChart(),
                    const SizedBox(height: 16),
                    _buildIncomeExpenseChart(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: _periods.map((p) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => setState(() => _selectedPeriod = p['value']!),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedPeriod == p['value'] ? AppConstants.primaryGreen : Colors.grey[300],
                foregroundColor: _selectedPeriod == p['value'] ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(p['label']!, style: const TextStyle(fontSize: 12)),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _service.getSummary(widget.walletId, _selectedPeriod),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final data = snapshot.data!;
        final income = (data['totalIncome'] ?? 0).toDouble();
        final expense = (data['totalExpense'] ?? 0).toDouble();
        final net = (data['net'] ?? 0).toDouble();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Summary', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem('Income', income, Colors.green),
                    _summaryItem('Expense', expense, Colors.red),
                    _summaryItem('Net', net, net >= 0 ? Colors.green : Colors.red),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text('\$${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildCategoryPieChart() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _service.getSpendingByCategory(widget.walletId, _selectedPeriod),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return const Center(child: Text("No data available"));
        }

        final categories = (snapshot.data!['categories'] as List);

        if (categories.isEmpty) {
          return const Center(child: Text("No spending recorded"));
        }

        // Use absolute values to prevent negative pie slices
        final totalSpending = categories.fold<double>(
          0,
              (sum, item) =>
          sum + ((item['total'] ?? 0).toDouble()).abs(),
        );

        final fallbackColors = [
          const Color(0xFF4CAF50),
          const Color(0xFF2196F3),
          const Color(0xFFFF9800),
          const Color(0xFF9C27B0),
          const Color(0xFFF44336),
          const Color(0xFF00BCD4),
          const Color(0xFF3F51B5),
          const Color(0xFFFFC107),
        ];

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "Spending by Category",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 45,
                      sections: List.generate(categories.length, (index) {
                        final c = categories[index];

                        final value =
                        ((c['total'] ?? 0).toDouble()).abs();

                        final percentage = totalSpending == 0
                            ? 0
                            : (value / totalSpending) * 100;

                        Color sectionColor;

                        try {
                          if (c['color'] != null) {
                            sectionColor =
                                Color(int.parse(c['color']));
                          } else {
                            sectionColor = fallbackColors[
                            index % fallbackColors.length];
                          }
                        } catch (_) {
                          sectionColor = fallbackColors[
                          index % fallbackColors.length];
                        }

                        return PieChartSectionData(
                          value: value,
                          title: percentage > 5
                              ? "${percentage.toStringAsFixed(1)}%"
                              : "",
                          color: sectionColor,
                          radius: 90,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Legend
                Column(
                  children: List.generate(categories.length, (index) {
                    final c = categories[index];
                    final value =
                    ((c['total'] ?? 0).toDouble()).abs();

                    Color legendColor;

                    try {
                      if (c['color'] != null) {
                        legendColor =
                            Color(int.parse(c['color']));
                      } else {
                        legendColor = fallbackColors[
                        index % fallbackColors.length];
                      }
                    } catch (_) {
                      legendColor = fallbackColors[
                      index % fallbackColors.length];
                    }

                    return Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: legendColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            "\$${value.toStringAsFixed(0)}",
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomeExpenseChart() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _service.getIncomeVsExpense(widget.walletId, _selectedPeriod),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final data = (snapshot.data!['data'] as List);
        if (data.isEmpty) return const Text('No data');

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Income vs Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      barGroups: List.generate(data.length, (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(toY: (data[i]['income'] ?? 0).toDouble(), color: Colors.green, width: 8),
                          BarChartRodData(toY: (data[i]['expense'] ?? 0).toDouble(), color: Colors.red, width: 8),
                        ],
                      )),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}