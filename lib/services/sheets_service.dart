import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/entry.dart';
import '../models/fixed_expense.dart';

class SheetsService {
  static const String _url = 'https://script.google.com/macros/s/AKfycbzQSFKLDssavkXfCC61ILp2fb51I9WWMkwWj42yt-9O4QB4rXs9j3TknkJk_rDj_W_3rw/exec';

  double _toDouble(dynamic value) {
    if (value == null || value.toString().isEmpty) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null || value.toString().isEmpty) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<String?> _get(Map<String, String> params) async {
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final url = '$_url?$queryString';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.body;
    } catch (e) {
      print('SheetsService error: $e');
    }
    return null;
  }

  // --- Entries ---
  Future<List<Entry>?> fetchEntries() async {
    final body = await _get({'action': 'getEntries'});
    if (body == null) return null;
    try {
      final List<dynamic> data = jsonDecode(body);
      return data.map((item) {
        try {
          // UTCで返ってくる日付はローカル時間に変換（Sheetsの仕様でJST→UTC変換される）
          final rawDate = DateTime.tryParse(item['date']?.toString() ?? '');
          final localDate = rawDate != null ? rawDate.toLocal() : DateTime.now();
          return Entry(
            id: item['id'] != null ? _toInt(item['id']) : null,
            amount: _toDouble(item['amount']),
            date: localDate,
            categoryId: _toInt(item['categoryid']),
            memo: item['memo']?.toString() ?? '',
            isFixed: item['isfixed'] == 1 || item['isfixed'] == '1',
          );
        } catch (_) { return null; }
      }).whereType<Entry>().toList();
    } catch (e) {
      print('Error parsing entries: $e');
      return [];
    }
  }

  Future<int?> addEntry(Entry entry) async {
    final result = await _get({
      'action': 'addEntry',
      'amount': entry.amount.toString(),
      'date': entry.date.toIso8601String(), // ローカル時間をそのまま送る（Sheetsが正しく解釈する）
      'categoryId': entry.categoryId.toString(),
      'memo': entry.memo ?? '',
      'isFixed': entry.isFixed ? '1' : '0',
    });
    if (result == null) return null;
    try {
      final data = jsonDecode(result);
      if (data['status'] == 'success') return _toInt(data['id']);
    } catch (_) {}
    return null;
  }

  Future<bool> deleteEntry(int id) async {
    final result = await _get({
      'action': 'deleteEntry',
      'id': id.toString(),
    });
    return result != null;
  }

  // --- Fixed Expenses ---
  Future<List<FixedExpense>?> fetchFixedExpenses() async {
    final body = await _get({'action': 'getFixedExpenses'});
    if (body == null) return null;
    try {
      final List<dynamic> data = jsonDecode(body);
      return data.map((item) {
        try {
          final name = item['name']?.toString() ?? '';
          final amount = _toDouble(item['amount']);
          if (name.isEmpty || amount <= 0) return null; // 壊れたデータをスキップ
          return FixedExpense(
            id: item['id'] != null ? _toInt(item['id']) : null,
            name: name,
            amount: amount,
            categoryId: _toInt(item['categoryid']),
            dayOfMonth: _toInt(item['dayofmonth']).clamp(1, 28),
          );
        } catch (_) { return null; }
      }).whereType<FixedExpense>().toList();
    } catch (e) {
      print('Error parsing fixed expenses: $e');
      return [];
    }
  }

  Future<int?> addFixedExpense(FixedExpense expense) async {
    final result = await _get({
      'action': 'addFixedExpense',
      'name': expense.name,
      'amount': expense.amount.toString(),
      'categoryId': expense.categoryId.toString(),
      'dayOfMonth': expense.dayOfMonth.toString(),
    });
    if (result == null) return null;
    try {
      final data = jsonDecode(result);
      if (data['status'] == 'success') return _toInt(data['id']);
    } catch (_) {}
    return null;
  }

  Future<bool> deleteFixedExpense(int id) async {
    final result = await _get({
      'action': 'deleteFixedExpense',
      'id': id.toString(),
    });
    return result != null;
  }
}
