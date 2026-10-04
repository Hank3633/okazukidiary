class LedgerAccount {
  const LedgerAccount({
    required this.id,
    required this.name,
    this.openingBalance = 0,
  });

  final String id;
  final String name;
  final double openingBalance;

  LedgerAccount copyWith({String? name, double? openingBalance}) =>
      LedgerAccount(
        id: id,
        name: name ?? this.name,
        openingBalance: openingBalance ?? this.openingBalance,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'openingBalance': openingBalance,
  };

  factory LedgerAccount.fromJson(Map<String, dynamic> json) => LedgerAccount(
    id: json['id'] as String,
    name: json['name'] as String,
    openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
  );
}
