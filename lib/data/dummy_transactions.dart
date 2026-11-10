import 'package:expenz/models/transaction_model.dart';

class DummyTransactions {
  static final List<TransactionModel> list = [
    TransactionModel(
      id: '1',
      title: 'Lunch',
      category: 'Food',
      amount: 350,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      type: TransactionType.expense,
    ),
    TransactionModel(
      id: '2',
      title: 'Bus fare',
      category: 'Transport',
      amount: 80,
      date: DateTime.now().subtract(const Duration(hours: 5)),
      type: TransactionType.expense,
    ),
    TransactionModel(
      id: '3',
      title: 'Salary',
      category: 'Salary',
      amount: 45000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: TransactionType.income,
    ),
  ];
}
