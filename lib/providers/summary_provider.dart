import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'entry_provider.dart';
import 'category_provider.dart';
import '../models/category.dart';

class MonthlySummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double fixedExpenseTotal;
  final double variableExpenseTotal;

  MonthlySummary({
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.balance = 0.0,
    this.fixedExpenseTotal = 0.0,
    this.variableExpenseTotal = 0.0,
  });
}

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final summaryProvider = Provider((ref) {
  final entries = ref.watch(entryProvider);
  final categories = ref.watch(categoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double fixedExpenseTotal = 0.0;
  double variableExpenseTotal = 0.0;

  final filteredEntries = entries.where((e) => 
    e.date.year == selectedDate.year && e.date.month == selectedDate.month
  );

  for (var entry in filteredEntries) {
    final category = categories.firstWhere(
      (c) => c.id == entry.categoryId,
      orElse: () => Category(name: '', type: CategoryType.expense, iconCode: 0, colorValue: 0),
    );

    if (category.type == CategoryType.income) {
      totalIncome += entry.amount;
    } else {
      totalExpense += entry.amount;
      if (entry.isFixed) {
        fixedExpenseTotal += entry.amount;
      } else {
        variableExpenseTotal += entry.amount;
      }
    }
  }

  return MonthlySummary(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    balance: totalIncome - totalExpense,
    fixedExpenseTotal: fixedExpenseTotal,
    variableExpenseTotal: variableExpenseTotal,
  );
});
