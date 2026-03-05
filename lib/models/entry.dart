class Entry {
  final int? id;
  final double amount;
  final DateTime date;
  final int categoryId;
  final String? memo;
  final bool isFixed; // 固定費による自動登録かどうか

  Entry({
    this.id,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.memo,
    this.isFixed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'memo': memo,
      'isFixed': isFixed ? 1 : 0,
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      categoryId: map['categoryId'],
      memo: map['memo'],
      isFixed: map['isFixed'] == 1,
    );
  }
}
