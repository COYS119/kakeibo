enum CategoryType { income, expense }

class Category {
  final int? id;
  final String name;
  final CategoryType type;
  final int iconCode; // IconData.codePoint
  final int colorValue; // Color.value

  Category({
    this.id,
    required this.name,
    required this.type,
    required this.iconCode,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index, // 0 for income, 1 for expense
      'iconCode': iconCode,
      'colorValue': colorValue,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      type: CategoryType.values[map['type']],
      iconCode: map['iconCode'],
      colorValue: map['colorValue'],
    );
  }
}
