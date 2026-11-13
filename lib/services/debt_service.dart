import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expenz/models/debt_account.dart';

class DebtService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  DebtService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : firestore = firestore ?? FirebaseFirestore.instance,
      auth = auth ?? FirebaseAuth.instance;
  DocumentReference<Map<String, dynamic>> get _user {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to manage debts.');
    return firestore.collection('users').doc(uid);
  }

  Future<void> create({
    required String name,
    required DebtKind kind,
    required int amountMinor,
    required String accountId,
    required bool movesCash,
    required DateTime date,
  }) async {
    _validate(amountMinor, date, allowZero: kind == DebtKind.creditCard);
    if (name.trim().isEmpty || name.trim().length > 40) {
      throw ArgumentError('Enter a name up to 40 characters.');
    }
    final debt = _user.collection('debt_accounts').doc();
    final value = DebtAccount(
      id: debt.id,
      name: name.trim(),
      kind: kind,
      principalMinor: amountMinor,
      createdAt: date,
      lastEntryId: debt.id,
    );
    final entry = DebtEntry(
      id: debt.id,
      debtId: debt.id,
      kind: kind,
      action: DebtAction.opening,
      amountMinor: amountMinor,
      accountId: accountId,
      movesCash: kind != DebtKind.creditCard && movesCash,
      date: date,
    );
    final batch = firestore.batch();
    batch.set(debt, value.toData());
    batch.set(_user.collection('debt_entries').doc(entry.id), entry.toData());
    await batch.commit();
  }

  Future<void> record({
    required DebtAccount debt,
    required int amountMinor,
    required String accountId,
    required DateTime date,
    bool charge = false,
  }) async {
    _validate(amountMinor, date);
    final ref = _user.collection('debt_accounts').doc(debt.id);
    final entryRef = _user.collection('debt_entries').doc();
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('This debt no longer exists.');
      final current = DebtAccount.fromData(snapshot.id, snapshot.data()!);
      if (date.isBefore(current.createdAt)) {
        throw StateError('Choose the opening date or a later date.');
      }
      if (charge && current.kind != DebtKind.creditCard) {
        throw StateError('Only credit cards accept purchases.');
      }
      if (!charge && amountMinor > current.remainingMinor) {
        throw StateError('The payment is higher than the remaining balance.');
      }
      final entry = DebtEntry(
        id: entryRef.id,
        debtId: current.id,
        kind: current.kind,
        action: charge ? DebtAction.charge : DebtAction.repayment,
        amountMinor: amountMinor,
        accountId: charge ? 'credit:${current.id}' : accountId,
        movesCash: !charge,
        date: date,
      );
      transaction.update(ref, {
        'principalMinor': current.principalMinor + (charge ? amountMinor : 0),
        'repaidMinor': current.repaidMinor + (charge ? 0 : amountMinor),
        'lastEntryId': entry.id,
      });
      transaction.set(entryRef, entry.toData());
      if (charge) {
        transaction.set(_user.collection('transactions').doc(entry.id), {
          'title': '${current.name} purchase',
          'category': 'Credit card purchase',
          'amount': amountMinor / 100,
          'date': Timestamp.fromDate(date),
          'type': 'expense',
          'accountId': entry.accountId,
        });
      }
    });
  }

  static void _validate(int amount, DateTime date, {bool allowZero = false}) {
    final now = DateTime.now();
    if (amount < 0 || !allowZero && amount == 0 || amount > 9007199254740991) {
      throw ArgumentError('Enter a positive amount.');
    }
    if (DateTime(
      date.year,
      date.month,
      date.day,
    ).isAfter(DateTime(now.year, now.month, now.day))) {
      throw ArgumentError('Future dates are not allowed.');
    }
  }
}
