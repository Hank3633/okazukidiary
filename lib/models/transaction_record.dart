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
}
