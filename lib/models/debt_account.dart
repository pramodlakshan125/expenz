import 'package:cloud_firestore/cloud_firestore.dart';

enum DebtKind { receivable, payable, creditCard }

enum DebtAction { opening, repayment, charge }

extension DebtKindLabel on DebtKind {
  String get label => switch (this) {
    DebtKind.receivable => 'Money to receive',
    DebtKind.payable => 'Money to repay',
    DebtKind.creditCard => 'Credit card balance',
  };
}

class DebtAccount {
  final String id;
  final String name;
  final DebtKind kind;
  final int principalMinor;
  final int repaidMinor;
  final DateTime createdAt;
  final String lastEntryId;
  const DebtAccount({
    required this.id,
    required this.name,
    required this.kind,
    required this.principalMinor,
    this.repaidMinor = 0,
    required this.createdAt,
    required this.lastEntryId,
  });
  int get remainingMinor => principalMinor - repaidMinor;
  factory DebtAccount.fromData(String id, Map<String, dynamic> data) =>
      DebtAccount(
        id: id,
        name: data['name'] as String,
        kind: DebtKind.values.byName(data['kind'] as String),
        principalMinor: data['principalMinor'] as int,
        repaidMinor: data['repaidMinor'] as int,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        lastEntryId: data['lastEntryId'] as String,
      );
  Map<String, dynamic> toData() => {
    'name': name,
    'kind': kind.name,
    'principalMinor': principalMinor,
    'repaidMinor': repaidMinor,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastEntryId': lastEntryId,
  };
}

class DebtEntry {
  final String id;
  final String debtId;
  final DebtKind kind;
  final DebtAction action;
  final int amountMinor;
  final String accountId;
  final bool movesCash;
  final DateTime date;
  const DebtEntry({
    required this.id,
    required this.debtId,
    required this.kind,
    required this.action,
    required this.amountMinor,
    required this.accountId,
    required this.movesCash,
    required this.date,
  });
  int get cashChangeMinor {
    if (!movesCash || action == DebtAction.charge) return 0;
    final incoming = action == DebtAction.opening
        ? kind == DebtKind.payable
        : kind == DebtKind.receivable;
    return incoming ? amountMinor : -amountMinor;
  }

  factory DebtEntry.fromData(String id, Map<String, dynamic> data) => DebtEntry(
    id: id,
    debtId: data['debtId'] as String,
    kind: DebtKind.values.byName(data['kind'] as String),
    action: DebtAction.values.byName(data['action'] as String),
    amountMinor: data['amountMinor'] as int,
    accountId: data['accountId'] as String,
    movesCash: data['movesCash'] as bool,
    date: (data['date'] as Timestamp).toDate(),
  );
  Map<String, dynamic> toData() => {
    'debtId': debtId,
    'kind': kind.name,
    'action': action.name,
    'amountMinor': amountMinor,
    'accountId': accountId,
    'movesCash': movesCash,
    'date': Timestamp.fromDate(date),
  };
}
