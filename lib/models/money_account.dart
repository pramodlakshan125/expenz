import 'transaction_model.dart';
import 'debt_account.dart';

class MoneyAccount {
  final String id;
  final String name;
  final int openingBalanceMinor;
  const MoneyAccount({
    required this.id,
    required this.name,
    required this.openingBalanceMinor,
  });

  int balanceMinor(
    Iterable<TransactionModel> transactions, {
    Iterable<DebtEntry> debtEntries = const [],
  }) =>
      openingBalanceMinor +
      transactions
          .where((entry) => (entry.accountId ?? 'cash') == id)
          .fold<int>(0, (sum, entry) => sum + entry.cashChangeMinor) +
      debtEntries
          .where((entry) => entry.accountId == id)
          .fold<int>(0, (sum, entry) => sum + entry.cashChangeMinor);

  MoneyAccount withCurrentBalance(
    int balanceMinor,
    Iterable<TransactionModel> transactions, {
    Iterable<DebtEntry> debtEntries = const [],
  }) => MoneyAccount(
    id: id,
    name: name,
    openingBalanceMinor:
        balanceMinor -
        (this.balanceMinor(transactions, debtEntries: debtEntries) -
            openingBalanceMinor),
  );
}
