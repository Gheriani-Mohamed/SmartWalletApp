import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/AnalyticsService.dart';
import 'package:smart_wallet_app/services/wallet_service.dart';
import 'package:smart_wallet_app/models/wallet_model.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:smart_wallet_app/screens/Analytics/AnalyticScrenn.dart';
import 'package:fl_chart/fl_chart.dart';

class GlobalAnalyticsScreen extends StatefulWidget {
  final String userId;

  const GlobalAnalyticsScreen({super.key, required this.userId});

  @override
  State<GlobalAnalyticsScreen> createState() => _GlobalAnalyticsScreenState();
}

class _GlobalAnalyticsScreenState extends State<GlobalAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final WalletService _walletService = WalletService();
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
        title: const Text('All Wallets Analytics'),
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
                    _buildGlobalSummary(),
                    const SizedBox(height: 16),
                    _buildGlobalCategoryChart(),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Per Wallet Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildWalletList(),
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

  Widget _buildGlobalSummary() {
    return FutureBuilder<List<WalletModel>>(
      future: _walletService.getUserWallets(widget.userId),
      builder: (context, walletsSnapshot) {
        if (!walletsSnapshot.hasData) return const CircularProgressIndicator();

        final wallets = walletsSnapshot.hasData ? walletsSnapshot.data! : [];

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(
            wallets.map((w) => _analyticsService.getSummary(w.id, _selectedPeriod)),
          ),
          builder: (context, summariesSnapshot) {
            if (!summariesSnapshot.hasData) return const CircularProgressIndicator();

            double totalIncome = 0;
            double totalExpense = 0;

            for (var summary in summariesSnapshot.data!) {
              totalIncome += (summary['totalIncome'] ?? 0).toDouble();
              totalExpense += (summary['totalExpense'] ?? 0).toDouble();
            }

            final net = totalIncome - totalExpense;

            return Card(
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppConstants.primaryGreen, AppConstants.primaryGreen.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('Total Across All Wallets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryItem('Income', totalIncome, Colors.white),
                        _summaryItem('Expense', totalExpense, Colors.white70),
                        _summaryItem('Net', net, net >= 0 ? Colors.white : Colors.red[200]!),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
        const SizedBox(height: 4),
        Text('\$${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildGlobalCategoryChart() {
    return FutureBuilder<List<WalletModel>>(
      future: _walletService.getUserWallets(widget.userId),
      builder: (context, walletsSnapshot) {
        if (walletsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!walletsSnapshot.hasData || walletsSnapshot.hasError) {
          return const Center(child: Text("No wallet data"));
        }

        final wallets = walletsSnapshot.data!;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(
            wallets.map(
                  (w) => _analyticsService.getSpendingByCategory(
                w.id,
                _selectedPeriod,
              ),
            ),
          ),
          builder: (context, categoriesSnapshot) {
            if (categoriesSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!categoriesSnapshot.hasData ||
                categoriesSnapshot.hasError) {
              return const Center(child: Text("No spending data"));
            }

            final Map<String, Map<String, dynamic>>
            combinedCategories = {};

            // Combine categories from all wallets
            for (var data in categoriesSnapshot.data!) {
              final categories = data['categories'] as List;

              for (var cat in categories) {
                final name = cat['name'];
                final value =
                ((cat['total'] ?? 0).toDouble()).abs();

                if (!combinedCategories.containsKey(name)) {
                  combinedCategories[name] = {
                    'name': name,
                    'total': 0.0,
                    'color': cat['color'],
                  };
                }

                combinedCategories[name]!['total'] =
                    (combinedCategories[name]!['total']
                    as double) +
                        value;
              }
            }

            final sortedCategories =
            combinedCategories.values.toList()
              ..sort((a, b) => (b['total'] as double)
                  .compareTo(a['total'] as double));

            if (sortedCategories.isEmpty) {
              return const Center(
                  child: Text("No spending recorded"));
            }

            final totalSpending = sortedCategories.fold<double>(
              0,
                  (sum, item) =>
              sum + (item['total'] as double),
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
                      "Total Spending by Category",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      height: 240,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 50,
                          sections: List.generate(
                              sortedCategories.length,
                                  (index) {
                                final c =
                                sortedCategories[index];
                                final value =
                                c['total'] as double;

                                final percentage =
                                totalSpending == 0
                                    ? 0
                                    : (value /
                                    totalSpending) *
                                    100;

                                Color sectionColor;

                                try {
                                  if (c['color'] != null) {
                                    sectionColor = Color(
                                        int.parse(
                                            c['color']));
                                  } else {
                                    sectionColor =
                                    fallbackColors[index %
                                        fallbackColors
                                            .length];
                                  }
                                } catch (_) {
                                  sectionColor =
                                  fallbackColors[index %
                                      fallbackColors
                                          .length];
                                }

                                return PieChartSectionData(
                                  value: value,
                                  title: percentage > 5
                                      ? "${percentage.toStringAsFixed(1)}%"
                                      : "",
                                  color: sectionColor,
                                  radius: 100,
                                  titleStyle:
                                  const TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.bold,
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
                      children: List.generate(
                          sortedCategories.length,
                              (index) {
                            final c =
                            sortedCategories[index];
                            final value =
                            c['total'] as double;

                            Color legendColor;

                            try {
                              if (c['color'] != null) {
                                legendColor = Color(
                                    int.parse(
                                        c['color']));
                              } else {
                                legendColor =
                                fallbackColors[index %
                                    fallbackColors
                                        .length];
                              }
                            } catch (_) {
                              legendColor =
                              fallbackColors[index %
                                  fallbackColors
                                      .length];
                            }

                            return Padding(
                              padding:
                              const EdgeInsets.symmetric(
                                  vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration:
                                    BoxDecoration(
                                      color: legendColor,
                                      shape:
                                      BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(
                                      width: 8),
                                  Expanded(
                                    child: Text(
                                      c['name'],
                                      style:
                                      const TextStyle(
                                        fontWeight:
                                        FontWeight.w500,
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
      },
    );
  }

  Widget _buildWalletList() {
    return FutureBuilder<List<WalletModel>>(
      future: _walletService.getUserWallets(widget.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final wallets = snapshot.data!;

        if (wallets.isEmpty) {
          return const Center(child: Text('No wallets found'));
        }

        return Column(
          children: wallets.map((wallet) => _buildWalletSummaryCard(wallet)).toList(),
        );
      },
    );
  }

  Widget _buildWalletSummaryCard(WalletModel wallet) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _analyticsService.getSummary(wallet.id, _selectedPeriod),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            child: ListTile(
              leading: Icon(Icons.account_balance_wallet, color:Color (int.parse('4288585374'))  ),
              title: Text(wallet.name),
              subtitle: const Text('Loading...'),
            ),
          );
        }

        final data = snapshot.data!;
        final income = (data['totalIncome'] ?? 0).toDouble();
        final expense = (data['totalExpense'] ?? 0).toDouble();
        final net = (data['net'] ?? 0).toDouble();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalyticsScreen(
                    walletId: wallet.id,
                    userId: widget.userId,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Color (int.parse('4288585374')) , size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(wallet.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(wallet.type, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniSummaryItem('Income', income, Colors.green),
                      _miniSummaryItem('Expense', expense, Colors.red),
                      _miniSummaryItem('Net', net, net >= 0 ? Colors.green : Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _miniSummaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        const SizedBox(height: 2),
        Text('\$${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}