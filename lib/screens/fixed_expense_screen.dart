import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fixed_expense_provider.dart';
import '../providers/category_provider.dart';
import '../models/fixed_expense.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class FixedExpenseScreen extends ConsumerStatefulWidget {
  const FixedExpenseScreen({super.key});

  @override
  ConsumerState<FixedExpenseScreen> createState() => _FixedExpenseScreenState();
}

class _FixedExpenseScreenState extends ConsumerState<FixedExpenseScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  int _dayOfMonth = 1;
  Category? _selectedCategory;

  void _addFixedExpense() {
    final name = _nameController.text;
    final amount = double.tryParse(_amountController.text);
    
    if (name.isEmpty || amount == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべての項目を入力し、カテゴリを選択してください')),
      );
      return;
    }

    final fixed = FixedExpense(
      name: name,
      amount: amount,
      categoryId: _selectedCategory!.id!,
      dayOfMonth: _dayOfMonth,
    );

    ref.read(fixedExpenseProvider.notifier).addFixedExpense(fixed);
    _nameController.clear();
    _amountController.clear();
    _selectedCategory = null;
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('固定費を登録しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fixedExpenses = ref.watch(fixedExpenseProvider);
    final categories = ref.watch(categoryProvider).where((c) => c.type == CategoryType.expense).toList();
    final currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('固定費管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: () => _showAddDialog(context, categories),
              icon: const Icon(Icons.add),
              label: const Text('固定費を追加'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
          ),
          Expanded(
            child: fixedExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        const Text('登録された固定費はありません', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    itemCount: fixedExpenses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = fixedExpenses[index];
                      final itemKey = ValueKey('fixed_${item.id ?? index}');
                      return Dismissible(
                        key: itemKey,
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          if (item.id != null) {
                            ref.read(fixedExpenseProvider.notifier).deleteFixedExpense(item.id!);
                          }
                        },
                        child: GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_month, size: 14, color: theme.colorScheme.primary.withOpacity(0.5)),
                                      const SizedBox(width: 4),
                                      Text('毎月 ${item.dayOfMonth}日 振替', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                currencyFormat.format(item.amount), 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.secondary)
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
  floatingActionButton: FloatingActionButton.extended(
    onPressed: () async {
      final selectedMonth = await _showMonthPicker(context);
      if (selectedMonth != null) {
        ref.read(fixedExpenseProvider.notifier).registerFixedExpensesForMonth(selectedMonth);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${selectedMonth.year}年${selectedMonth.month}月の固定費を記録しました'))
          );
        }
      }
    },
    label: const Text('一括登録'),
    icon: const Icon(Icons.auto_awesome),
    backgroundColor: theme.colorScheme.primary,
    elevation: 4,
  ),
);
}

Future<DateTime?> _showMonthPicker(BuildContext context) async {
  DateTime selectedDate = DateTime.now();
  final theme = Theme.of(context);

  return showDialog<DateTime>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setDialogState(() => selectedDate = DateTime(selectedDate.year - 1, selectedDate.month)),
            ),
            Text('${selectedDate.year}年', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setDialogState(() => selectedDate = DateTime(selectedDate.year + 1, selectedDate.month)),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = selectedDate.month == month;
              return InkWell(
                onTap: () => Navigator.pop(context, DateTime(selectedDate.year, month)),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? theme.colorScheme.primary : Colors.grey.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$month月',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        ],
      ),
    ),
  );
}

void _showAddDialog(BuildContext context, List<Category> categories) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 12, left: 24, right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4, 
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Text('固定費の追加', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '項目名', hintText: '家賃、ネット代など'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '金額', prefixText: '¥ '),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('振替日', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _dayOfMonth,
                      underline: const SizedBox(),
                      items: List.generate(28, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text('$d 日'))).toList(),
                      onChanged: (val) => setModalState(() => _dayOfMonth = val!),
                    ),
                  ],
                ),
                const Divider(height: 32),
                const Text('カテゴリ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 80,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategory?.id == cat.id;
                    final color = Color(cat.colorValue);
                    return GestureDetector(
                      onTap: () => setModalState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.1) : Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(IconData(cat.iconCode, fontFamily: 'MaterialIcons'), color: color, size: 24),
                            const SizedBox(height: 4),
                            Text(cat.name, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _addFixedExpense,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                  ),
                  child: const Text('保存する', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
