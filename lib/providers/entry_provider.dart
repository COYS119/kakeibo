import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entry.dart';
import '../services/database_service.dart';

class EntryNotifier extends StateNotifier<List<Entry>> {
  EntryNotifier() : super([]) {
    loadEntries();
  }

  final _dbService = DatabaseService();

  Future<void> loadEntries({DateTime? start, DateTime? end}) async {
    final entries = await _dbService.getEntries(start: start, end: end);
    // 日付の降順でソート（最新が上）
    entries.sort((a, b) => b.date.compareTo(a.date));
    state = entries;
  }

  Future<void> addEntry(Entry entry) async {
    // ローカルに追加してソート
    final newState = [...state, entry];
    newState.sort((a, b) => b.date.compareTo(a.date));
    state = newState;
    
    await _dbService.insertEntry(entry);
  }

  // id ではなく Entry オブジェクトで削除（id=nullでも動作）
  Future<void> removeEntry(Entry entry) async {
    // まずローカルから削除（Dismissibleエラー防止）
    state = state.where((e) => e != entry).toList();
    // Sheets からも削除（id がある場合のみ）
    if (entry.id != null) {
      await _dbService.deleteEntry(entry.id!);
    }
  }
}

final entryProvider = StateNotifierProvider<EntryNotifier, List<Entry>>((ref) {
  return EntryNotifier();
});
