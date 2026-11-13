import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expenz/models/daily_settlement.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/models/wallet_entry.dart';
import 'package:expenz/models/savings_goal.dart';
import 'package:expenz/models/goal_contribution.dart';
import 'daily_budget_planner.dart';

class BudgetFirestoreCodec {
  static int money(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! num || !value.isFinite || value < 0) {
      throw FormatException('Invalid $key in budget data.');
    }
    return (value * 100).round();
  }

  static DateTime calendarDate(Object? value) {
    if (value is! String) throw const FormatException('Missing calendar date.');
    final date = DateTime.tryParse(value);
    if (date == null || DailyBudgetPlanner.dateKey(date) != value) {
      throw const FormatException('Invalid calendar date.');
    }
    return date;
  }

  static Map<String, dynamic> settlementData(DailySettlement value) => {
    'date': value.dayKey,
    'baseLimit': value.baseLimitMinor / 100,
    'adjustedLimit': value.adjustedLimitMinor / 100,
    'spent': value.spentMinor / 100,
    'leftover': value.leftoverMinor / 100,
    'overspent': value.overspentMinor / 100,
    'action': value.action.name,
    'walletChange': value.walletChangeMinor / 100,
    'carriedBefore': value.carriedBeforeMinor / 100,
    'carryAssigned': value.carryAssignedMinor / 100,
    'uncovered': value.uncoveredMinor / 100,
    'carriedAfter': value.carriedAfterMinor / 100,
    // Integer copy is used by security rules for exact money comparisons.
    'amountsMinor': {
      'baseLimit': value.baseLimitMinor,
      'adjustedLimit': value.adjustedLimitMinor,
      'spent': value.spentMinor,
      'leftover': value.leftoverMinor,
      'overspent': value.overspentMinor,
      'walletChange': value.walletChangeMinor,
      'carriedBefore': value.carriedBeforeMinor,
      'carryAssigned': value.carryAssignedMinor,
      'uncovered': value.uncoveredMinor,
      'carriedAfter': value.carriedAfterMinor,
    },
  };

  static DailySettlement settlement(String id, Map<String, dynamic> data) {
    final change = data['walletChange'];
    if (change is! num || !change.isFinite) {
      throw const FormatException('Invalid wallet change.');
    }
    final value = DailySettlement(
      date: calendarDate(data['date']),
      baseLimitMinor: money(data, 'baseLimit'),
      adjustedLimitMinor: money(data, 'adjustedLimit'),
      spentMinor: money(data, 'spent'),
      action: SettlementAction.values.byName(data['action'] as String),
      walletChangeMinor: (change * 100).round(),
      carriedBeforeMinor: money(data, 'carriedBefore'),
      carryAssignedMinor: money(data, 'carryAssigned'),
    );
    if (value.dayKey != id ||
        value.leftoverMinor != money(data, 'leftover') ||
        value.overspentMinor != money(data, 'overspent') ||
        value.uncoveredMinor != money(data, 'uncovered') ||
        value.carriedAfterMinor != money(data, 'carriedAfter')) {
      throw const FormatException('Inconsistent saved settlement.');
    }
    final exact = data['amountsMinor'];
    final expected = settlementData(value)['amountsMinor'] as Map<String, int>;
    if (exact is! Map ||
        exact.length != expected.length ||
        expected.entries.any(
          (entry) =>
              exact[entry.key] is! int || exact[entry.key] != entry.value,
        )) {
      throw const FormatException('Inconsistent settlement cents.');
    }
    return value;
  }

  static Map<String, dynamic> walletData(DailySettlement value) => {
    'amount': value.walletChangeMinor.abs() / 100,
    'amountMinor': value.walletChangeMinor.abs(),
    'type': value.walletChangeMinor > 0 ? 'deposit' : 'withdraw',
    'date': value.dayKey,
    'relatedDay': value.dayKey,
  };

  static WalletEntry wallet(String id, Map<String, dynamic> data) {
    final source = data['source'] == null
        ? WalletEntrySource.settlement
        : WalletEntrySource.values.byName(data['source'] as String);
    if (source == WalletEntrySource.settlement &&
        (data['relatedDay'] != id || data['date'] != id)) {
      throw const FormatException('Wallet entry must match its settled day.');
    }
    if (data['amountMinor'] is! int ||
        data['amountMinor'] != money(data, 'amount')) {
      throw const FormatException('Inconsistent wallet cents.');
    }
    return WalletEntry(
      id: id,
      relatedDay: DailyBudgetPlanner.dateKey(calendarDate(data['relatedDay'])),
      date: source == WalletEntrySource.settlement
          ? calendarDate(data['date'])
          : instant(data['date']),
      amountMinor: money(data, 'amount'),
      type: WalletEntryType.values.byName(data['type'] as String),
      source: source,
      goalId: data['goalId'] as String?,
    );
  }

  static Map<String, dynamic> transferData(WalletEntry value) => {
    'amount': value.amountMinor / 100,
    'amountMinor': value.amountMinor,
    'type': value.type.name,
    'source': value.source.name,
    'date': Timestamp.fromDate(value.date),
    'relatedDay': value.relatedDay,
    if (value.goalId != null) 'goalId': value.goalId,
  };

  static Map<String, dynamic> contributionData(WalletEntry value) => {
    'goalId': value.goalId,
    'walletEntryId': value.id,
    'amount': value.amountMinor / 100,
    'amountMinor': value.amountMinor,
    'date': Timestamp.fromDate(value.date),
  };

  static GoalContribution contribution(String id, Map<String, dynamic> data) {
    if (data['walletEntryId'] != id ||
        data['amountMinor'] is! int ||
        data['amountMinor'] != money(data, 'amount')) {
      throw const FormatException('Invalid goal contribution.');
    }
    return GoalContribution(
      id: id,
      goalId: data['goalId'] as String,
      amountMinor: data['amountMinor'] as int,
      date: instant(data['date']),
    );
  }

  static SavingsGoal goal(String id, Map<String, dynamic> data) => SavingsGoal(
    id: id,
    title: data['title'] as String,
    targetMinor: money(data, 'target'),
    initialSavedMinor: data['saved'] == null ? 0 : money(data, 'saved'),
    createdAt: data['createdAt'] == null
        ? DateTime(1970)
        : instant(data['createdAt']),
  );

  static DateTime instant(Object? value) {
    if (value is Timestamp) return value.toDate();
    final date = value is String ? DateTime.tryParse(value) : null;
    if (date == null || !date.isUtc || date.toIso8601String() != value) {
      throw const FormatException('Invalid saved time.');
    }
    return date;
  }

  static TransactionModel transaction(String id, Map<String, dynamic> data) =>
      TransactionModel(
        id: id,
        title: data['title'] as String,
        category: data['category'] as String,
        amount: money(data, 'amount') / 100,
        date: (data['date'] as Timestamp).toDate(),
        type: TransactionType.values.byName(data['type'] as String),
      );
}
