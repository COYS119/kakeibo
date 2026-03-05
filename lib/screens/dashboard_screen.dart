import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/summary_provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryProvider);
    final currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ダッシュボード')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Month Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                DateFormat('yyyy年 MM月').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: '収入',
                    amount: summary.totalIncome,
                    color: Colors.green[600]!,
                    icon: Icons.add_circle_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: '支出',
                    amount: summary.totalExpense,
                    color: Colors.red[600]!,
                    icon: Icons.remove_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BalanceCard(balance: summary.balance),
            const SizedBox(height: 32),

            // Comparison Progress
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '予算消化率', 
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                )
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('支出内訳', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 12),
                            _LegendItem(label: '固定費', amount: summary.fixedExpenseTotal, color: AppTheme.primaryColor),
                            const SizedBox(height: 8),
                            _LegendItem(label: '変動費', amount: summary.variableExpenseTotal, color: AppTheme.accentColor),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: summary.totalIncome == 0 ? 0 : (summary.totalExpense / summary.totalIncome).clamp(0, 1),
                              strokeWidth: 10,
                              backgroundColor: Colors.black.withOpacity(0.05),
                              color: AppTheme.primaryColor,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            '${summary.totalIncome == 0 ? 0 : (summary.totalExpense / summary.totalIncome * 100).toInt()}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.title, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final theme = Theme.of(context);
    
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final theme = Theme.of(context);
    final color = balance >= 0 ? Colors.green[600]! : Colors.red[600]!;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              const Text('残高', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(
            currencyFormat.format(balance),
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _LegendItem({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label, 
            style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))
          )
        ),
        Text(
          currencyFormat.format(amount), 
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }
}
