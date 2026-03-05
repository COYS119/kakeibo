class FixedExpense {
  final int? id;
  final String name;
  final double amount;
  final int categoryId;
  final int dayOfMonth; // 毎月何日に登録するか

  FixedExpense({
    this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.dayOfMonth,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'categoryId': categoryId,
      'dayOfMonth': dayOfMonth,
    };
  }

  factory FixedExpense.fromMap(Map<String, dynamic> map) {
    return FixedExpense(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      categoryId: map['categoryId'],
      dayOfMonth: map['dayOfMonth'],
    );
  }
}
