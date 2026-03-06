import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fixed_expense.dart';
import '../services/database_service.dart';
import '../models/entry.dart';
import 'entry_provider.dart';

class FixedExpenseNotifier extends StateNotifier<List<FixedExpense>> {
  final Ref ref;
  FixedExpenseNotifier(this.ref) : super([]) {
    loadFixedExpenses();
  }

  final _dbService = DatabaseService();

  Future<void> loadFixedExpenses() async {
    state = await _dbService.getFixedExpenses();
  }

  Future<void> addFixedExpense(FixedExpense fixedExpense) async {
    // ローカルに即時追加（dayOfMonthが正しい内に保護）
    state = [...state, fixedExpense];
    await _dbService.insertFixedExpense(fixedExpense);
  }

  Future<void> deleteFixedExpense(int id) async {
    // ローカルから即時削除
    state = state.where((e) => e.id != id).toList();
    await _dbService.deleteFixedExpense(id);
  }

  Future<void> registerFixedExpensesForMonth(DateTime month) async {
    // Sheets再取得ではなく、現在の表示データ（state）を使用
    for (var expense in state) {
      final day = expense.dayOfMonth.clamp(1, 28); // 安全対策
      final date = DateTime(month.year, month.month, day);
      final entry = Entry(
        amount: expense.amount,
        date: date,
        categoryId: expense.categoryId,
        memo: '${expense.name} (固定費)',
        isFixed: true,
      );
      await _dbService.insertEntry(entry);
    }
    // 履歴 Provider を更新して即時反映させる
    await ref.read(entryProvider.notifier).loadEntries();
  }
}

final fixedExpenseProvider = StateNotifierProvider<FixedExpenseNotifier, List<FixedExpense>>((ref) {
  return FixedExpenseNotifier(ref);
});
