import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/entry_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class GraphScreen extends ConsumerWidget {
  const GraphScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entryProvider);
    final categories = ref.watch(categoryProvider);
    final theme = Theme.of(context);

    final now = DateTime.now();

    // 直近6ヶ月のデータを集計
    final monthlyData = <int, Map<String, double>>{};
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = month.month;
      monthlyData[key] = {'income': 0, 'expense': 0, 'monthIndex': (now.month - i).toDouble()};
    }

    for (final entry in entries) {
      final month = entry.date.month;
      if (monthlyData.containsKey(month)) {
        final category = categories.firstWhere(
          (c) => c.id == entry.categoryId,
          orElse: () => categories.isNotEmpty ? categories.first : Category(name: '', type: CategoryType.expense, iconCode: 0, colorValue: 0),
        );
        if (category.type == CategoryType.income) {
          monthlyData[month]!['income'] = (monthlyData[month]!['income'] ?? 0) + entry.amount;
        } else {
          monthlyData[month]!['expense'] = (monthlyData[month]!['expense'] ?? 0) + entry.amount;
        }
      }
    }

    // 当月の支出をカテゴリ別に集計
    final currentMonthExpenses = <int, double>{};
    for (final entry in entries) {
      if (entry.date.year == now.year && entry.date.month == now.month) {
        final category = categories.firstWhere(
          (c) => c.id == entry.categoryId,
          orElse: () => categories.isNotEmpty ? categories.first : Category(name: '', type: CategoryType.expense, iconCode: 0, colorValue: 0),
        );
        if (category.type == CategoryType.expense) {
          currentMonthExpenses[entry.categoryId] = (currentMonthExpenses[entry.categoryId] ?? 0) + entry.amount;
        }
      }
    }

    final totalExpense = currentMonthExpenses.values.fold(0.0, (a, b) => a + b);

    final sortedMonths = monthlyData.entries.toList();
    final maxY = sortedMonths.fold(0.0, (max, e) {
      final income = e.value['income'] ?? 0;
      final expense = e.value['expense'] ?? 0;
      return income > max ? (expense > income ? expense : income) : (expense > max ? expense : max);
    });
    final chartMaxY = maxY > 0 ? (maxY * 1.3).ceilToDouble() : 100000.0;

    final currencyFormat = NumberFormat.compact(locale: 'ja_JP');

    return Scaffold(
      appBar: AppBar(title: const Text('分析')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('収支推移（直近6ヶ月）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _ChartLegend(label: '収入', color: Colors.green[400]!),
                const SizedBox(width: 16),
                _ChartLegend(label: '支出', color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.6,
              child: GlassContainer(
                padding: const EdgeInsets.fromLTRB(16, 24, 24, 12),
                child: sortedMonths.isEmpty
                    ? const Center(child: Text('データがありません'))
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: chartMaxY,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final label = rodIndex == 0 ? '収入' : '支出';
                                return BarTooltipItem(
                                  '$label\n¥${NumberFormat('#,###').format(rod.toY.toInt())}',
                                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= sortedMonths.length) return const SizedBox();
                                  final monthNum = sortedMonths[idx].key;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text('${monthNum}月', style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const Text('0', style: TextStyle(fontSize: 9, color: Colors.grey));
                                  return Text(currencyFormat.format(value), style: const TextStyle(fontSize: 9, color: Colors.grey));
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(color: Colors.black.withOpacity(0.05), strokeWidth: 1),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(sortedMonths.length, (i) {
                            final data = sortedMonths[i].value;
                            return BarChartGroupData(
                              barsSpace: 6,
                              x: i,
                              barRods: [
                                BarChartRodData(toY: data['income'] ?? 0, color: Colors.green[400], width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                                BarChartRodData(toY: data['expense'] ?? 0, color: theme.colorScheme.primary, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                              ],
                            );
                          }),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
            Text('今月のカテゴリ別支出（${now.month}月）', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            currentMonthExpenses.isEmpty
                ? GlassContainer(
                    padding: const EdgeInsets.all(48),
                    child: const Center(child: Text('今月の支出データがありません', style: TextStyle(color: Colors.grey))),
                  )
                : AspectRatio(
                    aspectRatio: 1.4,
                    child: GlassContainer(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 35,
                                sections: currentMonthExpenses.entries.map((e) {
                                  final cat = categories.firstWhere(
                                    (c) => c.id == e.key,
                                    orElse: () => Category(name: '他', type: CategoryType.expense, iconCode: 0, colorValue: Colors.grey.value),
                                  );
                                  final pct = totalExpense > 0 ? (e.value / totalExpense * 100) : 0;
                                  return PieChartSectionData(
                                    color: Color(cat.colorValue),
                                    value: e.value,
                                    title: pct > 8 ? '${pct.toStringAsFixed(0)}%' : '',
                                    radius: 60,
                                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: currentMonthExpenses.entries.map((e) {
                                final cat = categories.firstWhere(
                                  (c) => c.id == e.key,
                                  orElse: () => Category(name: '他', type: CategoryType.expense, iconCode: 0, colorValue: Colors.grey.value),
                                );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(cat.colorValue), shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Text(cat.name, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final String label;
  final Color color;

  const _ChartLegend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
      ],
    );
  }
}
