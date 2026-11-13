import 'dart:async';
import 'dart:math';

import 'package:expenz/models/budget_ledger.dart';
import 'package:expenz/models/daily_budget_settings.dart';
import 'package:expenz/models/daily_settlement.dart';
import 'package:flutter/foundation.dart';
import 'budget_repository.dart';
import 'daily_budget_calculator.dart';
import 'daily_budget_planner.dart';
import 'savings_transfer_calculator.dart';
import 'package:expenz/models/savings_goal.dart';
import 'package:expenz/models/wallet_entry.dart';

/// Coordinates reads and queued actions. Widgets only display this state.
class BudgetController extends ChangeNotifier {
  final BudgetRepository repository;
  final DateTime Function() clock;
  StreamSubscription<BudgetLedger>? _subscription;
  Timer? _timer;
  bool _disposed = false;
  BudgetLedger? ledger;
  DailyBudgetPlan? plan;
  Object? error;
  bool saving = false;
  DailySettlement? _queuedSettlement;
  DailyBudgetSettings? _queuedSettings;
  String? _queuedEntryId;
  String? _queuedGoalId;
  int _sequence = 0;

  BudgetController({required this.repository, DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  void start() {
    _subscription ??= repository.watch().listen((value) {
      ledger = value;
      error = null;
      if (_queuedSettlement != null &&
          value.settlements.any(
            (closed) => closed.dayKey == _queuedSettlement!.dayKey,
          )) {
        _queuedSettlement = null;
      }
      if (_queuedSettings != null &&
          value.settings?.dailyLimitMinor == _queuedSettings!.dailyLimitMinor &&
          value.settings?.startDate == _queuedSettings!.startDate) {
        _queuedSettings = null;
      }
      if (value.walletEntries.any((entry) => entry.id == _queuedEntryId)) {
        _queuedEntryId = null;
      }
      if (value.goals.any((goal) => goal.id == _queuedGoalId)) {
        _queuedGoalId = null;
      }
      saving =
          _queuedSettlement != null ||
          _queuedSettings != null ||
          _queuedEntryId != null ||
          _queuedGoalId != null;
      refresh();
    }, onError: _failed);
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  void refresh() {
    if (_disposed) return;
    try {
      final settings = ledger?.settings;
      plan = settings == null
          ? null
          : const DailyBudgetPlanner().build(
              settings: settings,
              now: clock(),
              transactions: ledger!.transactions,
              settlements: ledger!.settlements,
            );
    } catch (failure) {
      error = failure;
      plan = null;
    }
    notifyListeners();
  }

  bool get canAct =>
      !_disposed &&
      ledger?.readyForSettlement == true &&
      !saving &&
      error == null;

  String _id(String prefix) =>
      '$prefix-${clock().microsecondsSinceEpoch}-${_sequence++}-${Random.secure().nextInt(1 << 30)}';

  void addToWallet(int amountMinor) {
    if (!canAct) throw StateError('Wait for your savings data to load.');
    _saveTransfer(
      const SavingsTransferCalculator().topUp(
        ledger: ledger!,
        amountMinor: amountMinor,
        id: _id('topup'),
        now: clock(),
      ),
    );
  }

  void transferToGoal({required String goalId, required int amountMinor}) {
    if (!canAct) throw StateError('Wait for your savings data to load.');
    _saveTransfer(
      const SavingsTransferCalculator().toGoal(
        ledger: ledger!,
        amountMinor: amountMinor,
        goalId: goalId,
        id: _id('goal'),
        now: clock(),
      ),
    );
  }

  void _saveTransfer(WalletEntry entry) {
    _queuedEntryId = entry.id;
    saving = true;
    notifyListeners();
    try {
      repository.saveWalletTransfer(entry, _failed);
    } catch (failure) {
      _failed(failure);
    }
  }

  void createGoal({required String title, required int targetMinor}) {
    if (!canAct) throw StateError('Wait for your savings data to load.');
    final value = SavingsGoal(
      id: _id('saving'),
      title: title.trim(),
      targetMinor: targetMinor,
      createdAt: clock(),
    );
    if (value.title.length > 60) {
      throw ArgumentError('Use no more than 60 characters.');
    }
    _queuedGoalId = value.id;
    saving = true;
    notifyListeners();
    try {
      repository.createGoal(value, _failed);
    } catch (failure) {
      _failed(failure);
    }
  }

  void setLimit(int limitMinor) {
    if (!canAct) throw StateError('Wait for your budget data to load.');
    if ((plan?.unsettledCount ?? 0) > 0) {
      throw StateError(
        'Review previous days before changing your daily limit.',
      );
    }
    final settings = DailyBudgetSettings(
      dailyLimitMinor: limitMinor,
      startDate: ledger!.settings?.startDate ?? clock(),
    );
    _queuedSettings = settings;
    saving = true;
    notifyListeners();
    try {
      repository.saveSettings(settings, _failed);
    } catch (failure) {
      _failed(failure);
    }
  }

  /// Only the earliest unresolved past day can be closed. Never close today.
  void settleNext({required String expectedDayKey, required bool useWallet}) {
    if (!canAct) {
      throw StateError('Wait for the previous save to finish locally.');
    }
    final next = plan?.nextUnsettledDay;
    if (next == null ||
        DailyBudgetPlanner.dateKey(next.date) != expectedDayKey) {
      throw StateError('This day changed. Please review it again.');
    }
    final result = const DailyBudgetCalculator().settle(
      day: next,
      walletBalanceMinor: ledger!.walletBalanceMinor,
      useWallet: useWallet,
    );
    final value = DailySettlement(
      date: next.date,
      baseLimitMinor: next.baseLimitMinor,
      adjustedLimitMinor: next.adjustedLimitMinor,
      spentMinor: next.spentMinor,
      action: result.action,
      walletChangeMinor: result.walletChangeMinor,
      carriedBeforeMinor: next.carriedBeforeMinor,
      carryAssignedMinor: next.carryAssignedMinor,
    );
    _queuedSettlement = value;
    saving = true;
    notifyListeners();
    try {
      repository.saveSettlement(value, _failed);
    } catch (failure) {
      _failed(failure);
    }
  }

  void _failed(Object failure) {
    if (_disposed) return;
    error = failure;
    _queuedSettings = null;
    _queuedSettlement = null;
    _queuedEntryId = null;
    _queuedGoalId = null;
    saving = false;
    notifyListeners();
  }

  void retry() {
    if (_disposed) return;
    error = null;
    final old = _subscription;
    _subscription = null;
    unawaited(old?.cancel());
    start();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
