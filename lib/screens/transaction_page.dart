import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/widgets/home/transaction_tile.dart';
import 'package:flutter/material.dart';

class TransactionPage extends StatelessWidget {
  final List<TransactionModel> transactions;
  final bool loading;
  final bool hasError;
  const TransactionPage({
    super.key,
    this.transactions = const [],
    this.loading = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? const Center(
              child: Text(
                'Could not load transactions. Check your connection.',
              ),
            )
          : transactions.isEmpty
          ? const Center(child: Text('No transactions yet. Tap + to add one.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: transactions.length,
              separatorBuilder: (_, index) => const Divider(),
              itemBuilder: (_, index) =>
                  TransactionTile(transaction: transactions[index]),
            ),
    );
  }
}
