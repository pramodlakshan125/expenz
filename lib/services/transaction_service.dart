import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expenz/models/transaction_model.dart';

class TransactionService {
  static final _errors = StreamController<Object>.broadcast();
  static Stream<Object> get writeErrors => _errors.stream;

  /// Firestore updates its local cache immediately; do not wait for its server
  /// acknowledgement in an offline UI. Keep listening for rejected writes.
  void queue(TransactionModel transaction) {
    unawaited(
      add(transaction).catchError((Object error, StackTrace stack) {
        _errors.add(error);
      }),
    );
  }

  CollectionReference<Map<String, dynamic>> get _collection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please sign in to save transactions.');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions');
  }

  Stream<List<TransactionModel>> watch() => _collection
      .orderBy('date', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return TransactionModel(
            id: doc.id,
            title: data['title'] as String,
            category: data['category'] as String,
            amount: (data['amount'] as num).toDouble(),
            date: (data['date'] as Timestamp).toDate(),
            type: data['type'] == 'income'
                ? TransactionType.income
                : TransactionType.expense,
          );
        }).toList(),
      );

  Future<void> add(TransactionModel transaction) =>
      _collection.doc(transaction.id).set({
        'title': transaction.title,
        'category': transaction.category,
        'amount': transaction.amount,
        'date': Timestamp.fromDate(transaction.date),
        'type': transaction.type.name,
      });
}
