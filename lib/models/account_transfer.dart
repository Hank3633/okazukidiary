class AccountTransfer {
  const AccountTransfer({
    required this.id,
    required this.sourceAccountId,
    required this.targetAccountId,
    required this.amount,
    required this.date,
  });

  final String id;
  final String sourceAccountId;
  final String targetAccountId;
  final double amount;
  final DateTime date;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceAccountId': sourceAccountId,
    'targetAccountId': targetAccountId,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory AccountTransfer.fromJson(Map<String, dynamic> json) =>
      AccountTransfer(
        id: json['id'] as String,
        sourceAccountId: json['sourceAccountId'] as String,
        targetAccountId: json['targetAccountId'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );
}
