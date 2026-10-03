import 'category_item.dart';

class TransactionRecord {
  const TransactionRecord({
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
  });
  final CategoryItem category;
  final double amount;
  final bool isIncome;
  final DateTime date;

  TransactionRecord copyWith({
    CategoryItem? category,
    double? amount,
    bool? isIncome,
    DateTime? date,
  }) => TransactionRecord(
    category: category ?? this.category,
    amount: amount ?? this.amount,
    isIncome: isIncome ?? this.isIncome,
    date: date ?? this.date,
  );

  Map<String, dynamic> toJson() => {
    'category': category.toJson(),
    'amount': amount,
    'isIncome': isIncome,
    'date': date.toIso8601String(),
  };

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final amount = json['amount'];
    final date = json['date'];
    if (category is! Map || amount is! num || date is! String) {
      throw const FormatException('無效的記帳資料');
    }
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) {
      throw const FormatException('無效的記帳日期');
    }
    return TransactionRecord(
      category: CategoryItem.fromJson(Map<String, dynamic>.from(category)),
      amount: amount.toDouble(),
      isIncome: json['isIncome'] == true,
      date: parsedDate,
    );
  }
}
