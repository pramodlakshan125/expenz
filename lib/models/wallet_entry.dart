enum WalletEntryType { deposit, withdraw }

enum WalletEntrySource { settlement, manualTopUp, goalTransfer }

class WalletEntry {
  final String id;
  final String relatedDay;
  final DateTime date;
  final int amountMinor;
  final WalletEntryType type;
  final WalletEntrySource source;
  final String? goalId;

  WalletEntry({
    String? id,
    required this.relatedDay,
    required this.date,
    required this.amountMinor,
    required this.type,
    this.source = WalletEntrySource.settlement,
    this.goalId,
  }) : id = id ?? relatedDay {
    if (amountMinor <= 0) {
      throw ArgumentError('Wallet amount must be positive.');
    }
    if (this.id.isEmpty ||
        (source == WalletEntrySource.manualTopUp &&
            type != WalletEntryType.deposit) ||
        (source == WalletEntrySource.goalTransfer &&
            (type != WalletEntryType.withdraw ||
                goalId == null ||
                goalId!.isEmpty)) ||
        (source != WalletEntrySource.goalTransfer && goalId != null)) {
      throw ArgumentError('Wallet source does not match its transfer.');
    }
  }

  int get signedAmountMinor =>
      type == WalletEntryType.deposit ? amountMinor : -amountMinor;
}
