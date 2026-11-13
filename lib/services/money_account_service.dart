import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expenz/models/money_account.dart';
import 'package:expenz/models/debt_account.dart';
import 'package:expenz/models/transaction_model.dart';

class MoneyAccountService {
  static final _errors = StreamController<Object>.broadcast();
  static Stream<Object> get writeErrors => _errors.stream;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  MoneyAccountService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : firestore = firestore ?? FirebaseFirestore.instance,
      auth = auth ?? FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> get _accounts {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to manage accounts.');
    return firestore.collection('users').doc(uid).collection('money_accounts');
  }

  Stream<List<MoneyAccount>> watch() => _accounts
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => decode(doc.id, doc.data())).toList(),
      );
  static MoneyAccount decode(String id, Map<String, dynamic> data) =>
      MoneyAccount(
        id: id,
        name: data['name'] as String,
        openingBalanceMinor: data['openingBalanceMinor'] as int,
      );

  /// Balance edits change the starting amount, keeping transaction history intact.
  void save({
    MoneyAccount? account,
    required String name,
    required int balanceMinor,
    required Iterable<TransactionModel> transactions,
    Iterable<DebtEntry> debtEntries = const [],
    required void Function(Object) onError,
  }) {
    final doc = account == null ? _accounts.doc() : _accounts.doc(account.id);
    final starting =
        (account ??
                MoneyAccount(id: doc.id, name: name, openingBalanceMinor: 0))
            .withCurrentBalance(
              balanceMinor,
              transactions,
              debtEntries: debtEntries,
            )
            .openingBalanceMinor;
    final write = doc.set({'name': name, 'openingBalanceMinor': starting});
    unawaited(
      write.catchError((Object error) {
        _errors.add(error);
        onError(error);
      }),
    );
  }
}
