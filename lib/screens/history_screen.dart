import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/entry_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import '../models/entry.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  // ローカルでの削除済みエントリを一意なキーで追跡（Dismissible バグ回避）
  final Set<String> _deletingItemKeys = {};

  String _getEntryKey(Entry entry, int fallbackIndex) {
    if (entry.id != null) return 'id_${entry.id}';
    return 'temp_${entry.date.millisecondsSinceEpoch}_${entry.amount}_$fallbackIndex';
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entryProvider);
    final categories = ref.watch(categoryProvider);
    final currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('履歴一覧')),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: theme.colorScheme.primary.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text('データがありません', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final itemKey = _getEntryKey(entry, index);
                
                if (_deletingItemKeys.contains(itemKey)) {
                  return const SizedBox.shrink();
                }

                final category = categories.firstWhere(
                  (c) => c.id == entry.categoryId,
                  orElse: () => categories.isNotEmpty ? categories.first : Category(name: '不明', type: CategoryType.expense, iconCode: 0, colorValue: 0),
                );

                return Dismissible(
                  key: Key(itemKey),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('削除', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.delete_outline, color: Colors.white),
                      ],
                    ),
                  ),
                  onDismissed: (_) {
                    setState(() => _deletingItemKeys.add(itemKey));
                    ref.read(entryProvider.notifier).removeEntry(entry);
                  },
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(category.colorValue).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            IconData(category.iconCode, fontFamily: 'MaterialIcons'),
                            color: Color(category.colorValue),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('yyyy/MM/dd').format(entry.date) + (entry.memo != null && entry.memo!.isNotEmpty ? ' - ${entry.memo}' : ''),
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), 
                                  fontSize: 12
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          (category.type == CategoryType.income ? '+ ' : '- ') + currencyFormat.format(entry.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: category.type == CategoryType.income ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
