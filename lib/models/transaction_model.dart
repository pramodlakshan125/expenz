enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? accountId;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.accountId,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isCreditPurchase => accountId?.startsWith('credit:') ?? false;
  int get cashChangeMinor =>
      isCreditPurchase ? 0 : (isIncome ? 1 : -1) * (amount * 100).round();
}
