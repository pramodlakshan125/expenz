import 'dart:async';
import 'package:expenz/models/budget_ledger.dart';
import 'package:expenz/models/daily_budget_settings.dart';
import 'package:expenz/models/daily_settlement.dart';
import 'package:expenz/services/budget_repository.dart';
import 'package:expenz/models/wallet_entry.dart';
import 'package:expenz/models/savings_goal.dart';

class FakeBudgetRepository implements BudgetRepository {
  final events = StreamController<BudgetLedger>.broadcast(sync: true);
  final savedDays = <DailySettlement>[];
  final savedSettings = <DailyBudgetSettings>[];
  final savedTransfers = <WalletEntry>[];
  final savedGoals = <SavingsGoal>[];
  void Function(Object)? rejectLastWrite;

  @override
  Stream<BudgetLedger> watch() => events.stream;

  @override
  void saveSettings(
    DailyBudgetSettings settings,
    void Function(Object) onError,
  ) {
    savedSettings.add(settings);
    rejectLastWrite = onError;
  }

  @override
  void saveSettlement(DailySettlement value, void Function(Object) onError) {
    savedDays.add(value);
    rejectLastWrite = onError;
  }

  @override
  void saveWalletTransfer(WalletEntry value, void Function(Object) onError) {
    savedTransfers.add(value);
    rejectLastWrite = onError;
  }

  @override
  void createGoal(SavingsGoal value, void Function(Object) onError) {
    savedGoals.add(value);
    rejectLastWrite = onError;
  }
}
