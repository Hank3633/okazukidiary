import 'category_item.dart';

class TransactionRecord {
  const TransactionRecord({
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
    this.accountId = 'cash',
  });
  final CategoryItem category;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String accountId;

  TransactionRecord copyWith({
    CategoryItem? category,
    double? amount,
    bool? isIncome,
    DateTime? date,
    String? accountId,
  }) => TransactionRecord(
    category: category ?? this.category,
    amount: amount ?? this.amount,
    isIncome: isIncome ?? this.isIncome,
    date: date ?? this.date,
    accountId: accountId ?? this.accountId,
  );

  Map<String, dynamic> toJson() => {
    'category': category.toJson(),
    'amount': amount,
    'isIncome': isIncome,
    'date': date.toIso8601String(),
    'accountId': accountId,
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
      accountId: json['accountId'] as String? ?? 'cash',
    );
  }
}
