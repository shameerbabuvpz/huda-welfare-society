class FinanceCategory {
  final int id;
  final int organizationId;
  final String name;
  final String type; // 'income' or 'expense'

  FinanceCategory({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.type,
  });

  factory FinanceCategory.fromJson(Map<String, dynamic> json) {
    return FinanceCategory(
      id: json['id'],
      organizationId: json['organization_id'],
      name: json['name'],
      type: json['type'],
    );
  }
}

class FinanceTransaction {
  final int id;
  final int organizationId;
  final int categoryId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String date;
  final String? description;
  final String? categoryName;

  FinanceTransaction({
    required this.id,
    required this.organizationId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    this.categoryName,
  });

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) {
    return FinanceTransaction(
      id: json['id'],
      organizationId: json['organization_id'],
      categoryId: json['category_id'],
      type: json['type'],
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      date: json['date'],
      description: json['description'],
      categoryName: json['category_name'],
    );
  }
}
