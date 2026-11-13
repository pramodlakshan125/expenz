import 'package:expenz/models/transaction_model.dart';

/// The savings wallet is already part of bank + cash, so it is not added again.
class BalanceReconciliation {
  const BalanceReconciliation();

  TransactionModel? adjustment({
    required int recordedBalanceMinor,
    required int bankMinor,
    required int cashMinor,
    required DateTime now,
    required String id,
  }) {
    if (bankMinor < 0 || cashMinor < 0) {
      throw ArgumentError('Bank and cash balances cannot be negative.');
    }
    final difference = bankMinor + cashMinor - recordedBalanceMinor;
    if (difference == 0) return null;
    return TransactionModel(
      id: id,
      title: difference < 0
          ? 'Unrecorded expense'
          : 'Balance adjustment income',
      category: 'Balance adjustment',
      amount: difference.abs() / 100,
      date: now,
      type: difference < 0 ? TransactionType.expense : TransactionType.income,
    );
  }
}
