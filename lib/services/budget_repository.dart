import 'dart:async';
import 'money_account_service.dart';
import 'package:expenz/models/debt_account.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expenz/models/budget_ledger.dart';
import 'package:expenz/models/daily_budget_settings.dart';
import 'package:expenz/models/daily_settlement.dart';
import 'package:expenz/models/wallet_entry.dart';
import 'package:expenz/models/savings_goal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'budget_firestore_codec.dart';
import 'daily_budget_settings_service.dart';

abstract class BudgetRepository {
  Stream<BudgetLedger> watch();
  void saveSettings(
    DailyBudgetSettings settings,
    void Function(Object) onError,
  );
  void saveSettlement(DailySettlement value, void Function(Object) onError);
  void saveWalletTransfer(WalletEntry value, void Function(Object) onError);
  void createGoal(SavingsGoal value, void Function(Object) onError);
}

class FirestoreBudgetRepository implements BudgetRepository {
  static final _writeErrors = StreamController<Object>.broadcast();
  static Stream<Object> get writeErrors => _writeErrors.stream;

  void _reportWriteError(Object error, void Function(Object) onError) {
    _writeErrors.add(error);
    onError(error);
  }

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  late final String _uid =
      auth.currentUser?.uid ??
      (throw StateError('Sign in to manage your budget.'));

  FirestoreBudgetRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : firestore = firestore ?? FirebaseFirestore.instance,
      auth = auth ?? FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> get _user =>
      firestore.collection('users').doc(_uid);

  @override
  Stream<BudgetLedger> watch() {
    late StreamController<BudgetLedger> output;
    final subscriptions = <StreamSubscription<dynamic>>[];
    DailyBudgetSettingsState? settings;
    final snapshots = <String, QuerySnapshot<Map<String, dynamic>>>{};
    var cacheReady = false;
    var markingCache = false;
    var active = true;
    SharedPreferences? preferences;
    final key = 'budget_cache_ready_v2_$_uid';

    void publish() {
      if (!active ||
          output.isClosed ||
          settings == null ||
          snapshots.length != 8) {
        return;
      }
      try {
        final settlements = snapshots['daily_settlements']!.docs
            .map((doc) => BudgetFirestoreCodec.settlement(doc.id, doc.data()))
            .toList();
        final entries = snapshots['wallet_entries']!.docs
            .map((doc) => BudgetFirestoreCodec.wallet(doc.id, doc.data()))
            .toList();
        final walletByDay = {
          for (final entry in entries.where(
            (value) => value.source == WalletEntrySource.settlement,
          ))
            entry.relatedDay: entry,
        };
        // A batch is atomic in Firestore, but its separate listeners may fire
        // one after another. Never expose half of a settlement to the UI.
        for (final closed in settlements) {
          final amount =
              walletByDay.remove(closed.dayKey)?.signedAmountMinor ?? 0;
          if (amount != closed.walletChangeMinor) return;
        }
        if (walletByDay.isNotEmpty) return;
        final goals = snapshots['goals']!.docs
            .map((doc) => BudgetFirestoreCodec.goal(doc.id, doc.data()))
            .toList();
        final contributions = snapshots['goal_contributions']!.docs
            .map((doc) => BudgetFirestoreCodec.contribution(doc.id, doc.data()))
            .toList();
        final linked = {
          for (final contribution in contributions)
            contribution.id: contribution,
        };
        for (final entry in entries.where(
          (value) => value.source == WalletEntrySource.goalTransfer,
        )) {
          final contribution = linked.remove(entry.id);
          if (contribution == null ||
              contribution.goalId != entry.goalId ||
              contribution.amountMinor != entry.amountMinor ||
              !contribution.date.isAtSameMomentAs(entry.date)) {
            return;
          }
        }
        if (linked.isNotEmpty ||
            contributions.any(
              (entry) => !goals.any((goal) => goal.id == entry.goalId),
            )) {
          return;
        }
        final fromCache =
            settings!.isFromCache ||
            snapshots.values.any((value) => value.metadata.isFromCache);
        final pending =
            settings!.hasPendingWrites ||
            snapshots.values.any((value) => value.metadata.hasPendingWrites);
        if (!fromCache && !pending && !cacheReady && !markingCache) {
          cacheReady = true;
          markingCache = true;
          unawaited(
            preferences!
                .setBool(key, true)
                .then<void>(
                  (_) {},
                  onError: (Object error, StackTrace stack) {
                    if (active && !output.isClosed) {
                      output.addError(error, stack);
                    }
                  },
                ),
          );
        }
        final debts = snapshots['debt_accounts']!.docs
            .map((doc) => DebtAccount.fromData(doc.id, doc.data()))
            .toList();
        final debtEntries = snapshots['debt_entries']!.docs
            .map((doc) => DebtEntry.fromData(doc.id, doc.data()))
            .toList();
        final transactions = snapshots['transactions']!.docs
            .map((doc) => BudgetFirestoreCodec.transaction(doc.id, doc.data()))
            .toList();
        // Listeners can deliver different halves of a batch in separate callbacks.
        // Only publish when debt totals, cash flows, and credit purchases agree.
        for (final debt in debts) {
          final entries = debtEntries
              .where((entry) => entry.debtId == debt.id)
              .toList();
          if (!entries.any((entry) => entry.id == debt.lastEntryId)) return;
          final principal = entries
              .where((entry) => entry.action != DebtAction.repayment)
              .fold<int>(0, (total, entry) => total + entry.amountMinor);
          final repaid = entries
              .where((entry) => entry.action == DebtAction.repayment)
              .fold<int>(0, (total, entry) => total + entry.amountMinor);
          if (principal != debt.principalMinor || repaid != debt.repaidMinor) {
            return;
          }
        }
        for (final entry in debtEntries) {
          if (!debts.any((debt) => debt.id == entry.debtId)) return;
          if (entry.action == DebtAction.charge &&
              !transactions.any(
                (transaction) =>
                    transaction.id == entry.id && transaction.isCreditPurchase,
              )) {
            return;
          }
        }
        if (transactions.any(
          (transaction) =>
              transaction.isCreditPurchase &&
              !debtEntries.any((entry) => entry.id == transaction.id),
        )) {
          return;
        }
        final ledger = BudgetLedger(
          accounts: snapshots['money_accounts']!.docs
              .map((doc) => MoneyAccountService.decode(doc.id, doc.data()))
              .toList(),
          settings: settings!.settings,
          transactions: transactions,
          debts: debts,
          debtEntries: debtEntries,
          settlements: settlements,
          walletEntries: entries,
          goals: goals,
          goalContributions: contributions,
          readyForSettlement: cacheReady || !fromCache,
          hasPendingWrites: pending,
          isFromCache: fromCache,
        );
        if (ledger.walletBalanceMinor < 0) {
          throw StateError(
            'Wallet history is inconsistent. Reconnect to sync.',
          );
        }
        output.add(ledger);
      } catch (error, stack) {
        output.addError(error, stack);
      }
    }

    output = StreamController<BudgetLedger>(
      onListen: () async {
        try {
          preferences = await SharedPreferences.getInstance();
          if (!active || output.isClosed) return;
          cacheReady = preferences!.getBool(key) ?? false;
          subscriptions.add(
            DailyBudgetSettingsService(
              firestore: firestore,
              auth: auth,
            ).watch().listen((value) {
              settings = value;
              publish();
            }, onError: output.addError),
          );
          for (final name in [
            'transactions',
            'daily_settlements',
            'wallet_entries',
            'goals',
            'goal_contributions',
            'money_accounts',
            'debt_accounts',
            'debt_entries',
          ]) {
            subscriptions.add(
              _user
                  .collection(name)
                  .snapshots(includeMetadataChanges: true)
                  .listen((value) {
                    snapshots[name] = value;
                    publish();
                  }, onError: output.addError),
            );
          }
        } catch (error, stack) {
          if (active && !output.isClosed) output.addError(error, stack);
        }
      },
      onCancel: () async {
        active = false;
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return output.stream;
  }

  @override
  void saveSettings(
    DailyBudgetSettings settings,
    void Function(Object) onError,
  ) {
    DailyBudgetSettingsService(firestore: firestore, auth: auth).save(
      settings,
      onError: (error, stack) => _reportWriteError(error, onError),
    );
  }

  @override
  void saveSettlement(DailySettlement value, void Function(Object) onError) {
    final batch = firestore.batch();
    batch.set(
      _user.collection('daily_settlements').doc(value.dayKey),
      BudgetFirestoreCodec.settlementData(value),
    );
    if (value.walletChangeMinor != 0) {
      batch.set(
        _user.collection('wallet_entries').doc(value.dayKey),
        BudgetFirestoreCodec.walletData(value),
      );
    }
    unawaited(
      batch.commit().catchError((Object error, StackTrace stack) {
        _reportWriteError(error, onError);
      }),
    );
  }

  @override
  void saveWalletTransfer(WalletEntry value, void Function(Object) onError) {
    if (value.source == WalletEntrySource.settlement) {
      throw ArgumentError('Use the day settlement flow for daily savings.');
    }
    final batch = firestore.batch();
    batch.set(
      _user.collection('wallet_entries').doc(value.id),
      BudgetFirestoreCodec.transferData(value),
    );
    if (value.source == WalletEntrySource.goalTransfer) {
      batch.set(
        _user.collection('goal_contributions').doc(value.id),
        BudgetFirestoreCodec.contributionData(value),
      );
    }
    unawaited(
      batch.commit().catchError((Object error, StackTrace stack) {
        _reportWriteError(error, onError);
      }),
    );
  }

  @override
  void createGoal(SavingsGoal value, void Function(Object) onError) {
    unawaited(
      _user
          .collection('goals')
          .doc(value.id)
          .set({
            'title': value.title,
            'target': value.targetMinor / 100,
            'saved': 0,
            'createdAt': Timestamp.fromDate(value.createdAt),
          })
          .catchError((Object error, StackTrace stack) {
            _reportWriteError(error, onError);
          }),
    );
  }
}
