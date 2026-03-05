import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/category.dart';
import '../models/entry.dart';
import '../models/fixed_expense.dart';
import 'package:flutter/material.dart';
import 'sheets_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  final SheetsService _sheetsService = SheetsService();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  // Web用のメモリ内データ
  final List<Category> _webCategories = [];
  final List<Entry> _webEntries = [];
  final List<FixedExpense> _webFixedExpenses = [];

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    String path = join(await getDatabasesPath(), 'kakeibo.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        iconCode INTEGER NOT NULL,
        colorValue INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        categoryId INTEGER NOT NULL,
        memo TEXT,
        isFixed INTEGER NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE fixed_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        categoryId INTEGER NOT NULL,
        dayOfMonth INTEGER NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    await _insertInitialCategories(db);
  }

  Future _insertInitialCategories(Database db) async {
    final initialCategories = _getInitialCategoryList();
    for (var category in initialCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  List<Category> _getInitialCategoryList() {
    return [
      Category(id: 1, name: '食費', type: CategoryType.expense, iconCode: Icons.restaurant.codePoint, colorValue: Colors.orange.value),
      Category(id: 16, name: '外食', type: CategoryType.expense, iconCode: Icons.local_pizza.codePoint, colorValue: Colors.amber.value),
      Category(id: 2, name: '日用品', type: CategoryType.expense, iconCode: Icons.shopping_bag.codePoint, colorValue: Colors.blue.value),
      Category(id: 3, name: '住居費', type: CategoryType.expense, iconCode: Icons.home.codePoint, colorValue: Colors.brown.value),
      Category(id: 4, name: '光熱費', type: CategoryType.expense, iconCode: Icons.lightbulb.codePoint, colorValue: Colors.yellow.value),
      Category(id: 5, name: '通信費', type: CategoryType.expense, iconCode: Icons.phone_android.codePoint, colorValue: Colors.purple.value),
      Category(id: 6, name: '交通費', type: CategoryType.expense, iconCode: Icons.directions_bus.codePoint, colorValue: Colors.green.value),
      Category(id: 7, name: '交際費', type: CategoryType.expense, iconCode: Icons.celebration.codePoint, colorValue: Colors.pink.value),
      Category(id: 8, name: '娯楽', type: CategoryType.expense, iconCode: Icons.sports_esports.codePoint, colorValue: Colors.indigo.value),
      Category(id: 17, name: '美容・衣服', type: CategoryType.expense, iconCode: Icons.checkroom.codePoint, colorValue: Colors.tealAccent.value),
      Category(id: 9, name: '保険', type: CategoryType.expense, iconCode: Icons.security.codePoint, colorValue: Colors.teal.value),
      Category(id: 10, name: '投資', type: CategoryType.expense, iconCode: Icons.trending_up.codePoint, colorValue: Colors.cyan.value),
      Category(id: 11, name: 'その他', type: CategoryType.expense, iconCode: Icons.more_horiz.codePoint, colorValue: Colors.grey.value),
      Category(id: 12, name: '給与', type: CategoryType.income, iconCode: Icons.payments.codePoint, colorValue: Colors.lightGreen.value),
      Category(id: 13, name: '賞与', type: CategoryType.income, iconCode: Icons.redeem.codePoint, colorValue: Colors.amber.value),
      Category(id: 14, name: '給付金', type: CategoryType.income, iconCode: Icons.child_care.codePoint, colorValue: Colors.blueAccent.value),
      Category(id: 15, name: '臨時収入', type: CategoryType.income, iconCode: Icons.add_card.codePoint, colorValue: Colors.deepOrange.value),
    ];
  }

  Future<List<Category>> getCategories() async {
    if (kIsWeb) {
      if (_webCategories.isEmpty) _webCategories.addAll(_getInitialCategoryList());
      return _webCategories;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<int> insertCategory(Category category) async {
    if (kIsWeb) {
      _webCategories.add(category);
      return _webCategories.length;
    }
    final db = await database;
    return await db!.insert('categories', category.toMap());
  }

  Future<List<Entry>> getEntries({DateTime? start, DateTime? end}) async {
    if (kIsWeb) {
      final sheetsEntries = await _sheetsService.fetchEntries();
      if (sheetsEntries != null) {
        _webEntries.clear();
        _webEntries.addAll(sheetsEntries);
      }
      
      return _webEntries.where((e) {
        if (start != null && e.date.isBefore(start)) return false;
        if (end != null && e.date.isAfter(end)) return false;
        return true;
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
    }
    
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;
    
    if (start != null && end != null) {
      where = 'date BETWEEN ? AND ?';
      whereArgs = [start.toIso8601String(), end.toIso8601String()];
    }

    final List<Map<String, dynamic>> maps = await db!.query(
      'entries',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Entry.fromMap(maps[i]));
  }

  Future<int> insertEntry(Entry entry) async {
    if (kIsWeb) {
      final id = await _sheetsService.addEntry(entry);
      if (id != null) {
        final newEntry = Entry(
          id: id,
          amount: entry.amount,
          date: entry.date,
          categoryId: entry.categoryId,
          memo: entry.memo,
          isFixed: entry.isFixed,
        );
        _webEntries.add(newEntry);
        return id;
      }
      return 0;
    }
    final db = await database;
    return await db!.insert('entries', entry.toMap());
  }

  Future<int> deleteEntry(int id) async {
    if (kIsWeb) {
      final success = await _sheetsService.deleteEntry(id);
      if (success) {
        _webEntries.removeWhere((e) => e.id == id);
      }
      return 1;
    }
    final db = await database;
    return await db!.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FixedExpense>> getFixedExpenses() async {
    if (kIsWeb) {
      final sheetsExpenses = await _sheetsService.fetchFixedExpenses();
      if (sheetsExpenses != null) {
        _webFixedExpenses.clear();
        _webFixedExpenses.addAll(sheetsExpenses);
      }
      return List.from(_webFixedExpenses);
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('fixed_expenses');
    return List.generate(maps.length, (i) => FixedExpense.fromMap(maps[i]));
  }

  Future<int> insertFixedExpense(FixedExpense fixedExpense) async {
    if (kIsWeb) {
      final id = await _sheetsService.addFixedExpense(fixedExpense);
      if (id != null) {
        final newExpense = FixedExpense(
          id: id,
          name: fixedExpense.name,
          amount: fixedExpense.amount,
          categoryId: fixedExpense.categoryId,
          dayOfMonth: fixedExpense.dayOfMonth,
        );
        _webFixedExpenses.add(newExpense);
        return id;
      }
      return 0;
    }
    final db = await database;
    return await db!.insert('fixed_expenses', fixedExpense.toMap());
  }

  Future<int> deleteFixedExpense(int id) async {
    if (kIsWeb) {
      final success = await _sheetsService.deleteFixedExpense(id);
      if (success) {
        _webFixedExpenses.removeWhere((e) => e.id == id);
      }
      return 1;
    }
    final db = await database;
    return await db!.delete('fixed_expenses', where: 'id = ?', whereArgs: [id]);
  }
}
