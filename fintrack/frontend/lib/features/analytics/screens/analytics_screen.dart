import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/analytics_model.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/stat_card.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedMonths = 6;
  int _touchedPieIndex = -1;

  final List<Color> _chartColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFEF4444), // Red
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF14B8A6), // Teal
    const Color(0xFF64748B), // Slate
  ];

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final monthlyAsync = ref.watch(monthlyAnalyticsProvider);
    final categoryAsync = ref.watch(categoryAnalyticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(analyticsSummaryProvider);
              ref.invalidate(monthlyAnalyticsProvider);
              ref.invalidate(categoryAnalyticsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsSummaryProvider);
          ref.invalidate(monthlyAnalyticsProvider);
          ref.invalidate(categoryAnalyticsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Cards
              summaryAsync.when(
                data: (summary) => Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Income',
                        amount: CurrencyFormatter.format(
                          summary.totalIncome,
                          symbol: settings.currencySymbol,
                        ),
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.income,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Total Expenses',
                        amount: CurrencyFormatter.format(
                          summary.totalExpenses,
                          symbol: settings.currencySymbol,
                        ),
                        icon: Icons.arrow_upward_rounded,
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Monthly Trend Bar Chart Section
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monthly Cashflow',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              _buildLegendItem('Income', AppColors.income),
                              const SizedBox(width: 12),
                              _buildLegendItem('Expense', AppColors.expense),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      monthlyAsync.when(
                        data: (monthlyList) {
                          if (monthlyList.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(child: Text('No monthly data recorded yet.')),
                            );
                          }

                          return SizedBox(
                            height: 220,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _calculateMaxY(monthlyList),
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final isIncomeRod = rodIndex == 0;
                                      final type = isIncomeRod ? 'Income' : 'Expense';
                                      return BarTooltipItem(
                                        '$type\n${CurrencyFormatter.format(rod.toY, symbol: settings.currencySymbol)}',
                                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 42,
                                      getTitlesWidget: (val, meta) {
                                        if (val == meta.max || val == 0) {
                                          return const SizedBox.shrink();
                                        }
                                        return Text(
                                          CurrencyFormatter.formatCompact(val, symbol: settings.currencySymbol),
                                          style: const TextStyle(fontSize: 10, color: AppColors.darkTextSecondary),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 && index < monthlyList.length) {
                                          final label = monthlyList[index].month.split(' ').first;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6.0),
                                            child: Text(
                                              label,
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (val) => FlLine(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    strokeWidth: 0.8,
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(monthlyList.length, (i) {
                                  final m = monthlyList[i];
                                  return BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: m.income,
                                        color: AppColors.income,
                                        width: 10,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                      ),
                                      BarChartRodData(
                                        toY: m.expense,
                                        color: AppColors.expense,
                                        width: 10,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => ErrorView(message: err.toString()),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Expense by Category Section
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expenses by Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      categoryAsync.when(
                        data: (catData) {
                          final expenses = catData.expenseCategories;
                          if (expenses.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(child: Text('No expense transactions recorded yet.')),
                            );
                          }

                          return Column(
                            children: [
                              // Donut Pie Chart
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    pieTouchData: PieTouchData(
                                      touchCallback: (event, pieTouchResponse) {
                                        setState(() {
                                          if (!event.isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection == null) {
                                            _touchedPieIndex = -1;
                                            return;
                                          }
                                          _touchedPieIndex = pieTouchResponse
                                              .touchedSection!.touchedSectionIndex;
                                        });
                                      },
                                    ),
                                    borderData: FlBorderData(show: false),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 50,
                                    sections: List.generate(expenses.length, (i) {
                                      final isTouched = i == _touchedPieIndex;
                                      final radius = isTouched ? 45.0 : 38.0;
                                      final item = expenses[i];
                                      final color = _chartColors[i % _chartColors.length];

                                      return PieChartSectionData(
                                        color: color,
                                        value: item.totalAmount,
                                        title: '${item.percentage.toStringAsFixed(0)}%',
                                        radius: radius,
                                        titleStyle: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Ranked Category Breakdown Progress Bars
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: expenses.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final item = expenses[i];
                                  final color = _chartColors[i % _chartColors.length];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                item.category,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '(${item.count})',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            CurrencyFormatter.format(item.totalAmount, symbol: settings.currencySymbol),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      LinearProgressIndicator(
                                        value: (item.percentage / 100).clamp(0.0, 1.0),
                                        backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        valueColor: AlwaysStoppedAnimation<Color>(color),
                                        minHeight: 6,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox(
                          height: 150,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => ErrorView(message: err.toString()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  double _calculateMaxY(List<MonthlyBreakdown> list) {
    double maxVal = 0.0;
    for (final m in list) {
      if (m.income > maxVal) maxVal = m.income;
      if (m.expense > maxVal) maxVal = m.expense;
    }
    return maxVal > 0 ? maxVal * 1.25 : 100.0;
  }
}
