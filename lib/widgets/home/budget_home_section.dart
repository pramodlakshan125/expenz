import 'dart:async';
import 'package:expenz/services/money_account_service.dart';
import 'package:expenz/models/debt_account.dart';
import 'debts_sheet.dart';

import 'package:expenz/services/budget_controller.dart';
import 'package:expenz/services/budget_repository.dart';
import 'package:expenz/services/daily_budget_planner.dart';
import 'package:expenz/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'balance_card.dart';
import 'accounts_sheet.dart';
import 'daily_limit_sheet.dart';
import 'settlement_sheet.dart';
import 'funds_summary.dart';
import 'settlement_history_sheet.dart';

class BudgetHomeSection extends StatefulWidget {
  final bool isActive;
  final BudgetRepository? repository;
  const BudgetHomeSection({super.key, this.isActive = true, this.repository});

  @override
  State<BudgetHomeSection> createState() => _BudgetHomeSectionState();
}

class _BudgetHomeSectionState extends State<BudgetHomeSection>
    with WidgetsBindingObserver {
  late final BudgetController _controller;
  StreamSubscription<Object>? _transactionErrors;
  StreamSubscription<Object>? _savingsErrors;
  StreamSubscription<Object>? _accountErrors;
  bool _reviewOpen = false;
  bool _limitOpen = false;
  String? _promptedOnDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = BudgetController(
      repository: widget.repository ?? FirestoreBudgetRepository(),
    )..addListener(_changed);
    _controller.start();
    _accountErrors = MoneyAccountService.writeErrors.listen((_) {
      _message(
        'An account balance could not sync. Check your accounts and retry.',
      );
    });
    _transactionErrors = TransactionService.writeErrors.listen((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A transaction could not sync. Review your balance and try again.',
          ),
        ),
      );
    });
    _savingsErrors = FirestoreBudgetRepository.writeErrors.listen((_) {
      _message(
        'A savings change could not sync. Review your wallet and goals, then retry.',
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.refresh();
  }

  @override
  void didUpdateWidget(covariant BudgetHomeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _changed();
  }

  void _changed() {
    if (!mounted) return;
    final today = DailyBudgetPlanner.dateKey(_controller.clock());
    if (!widget.isActive ||
        !_controller.canAct ||
        _reviewOpen ||
        _limitOpen ||
        (_controller.plan?.unsettledCount ?? 0) == 0 ||
        _promptedOnDay == today) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.isActive &&
          !_reviewOpen &&
          !_limitOpen &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        _promptedOnDay = today;
        _review();
      }
    });
  }

  Future<void> _review() async {
    if (_reviewOpen) return;
    _reviewOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SettlementSheet(controller: _controller),
    );
    _reviewOpen = false;
  }

  Future<void> _editLimit() async {
    _limitOpen = true;
    final limit = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DailyLimitSheet(
        currentLimitMinor: _controller.ledger?.settings?.dailyLimitMinor,
      ),
    );
    _limitOpen = false;
    if (!mounted || limit == null) return;
    try {
      _controller.setLimit(limit);
    } catch (error) {
      _message('$error');
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _accounts() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AccountsSheet(controller: _controller),
  );
  Future<void> _debts(DebtKind kind) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DebtsSheet(controller: _controller, kind: kind),
  );
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_transactionErrors?.cancel());
    unawaited(_savingsErrors?.cancel());
    unawaited(_accountErrors?.cancel());
    _controller.removeListener(_changed);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final ledger = _controller.ledger;
      final plan = _controller.plan;
      if (_controller.error != null) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Could not load or sync your budget. Reconnect and retry.',
                ),
                TextButton(
                  onPressed: _controller.retry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      if (ledger == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!ledger.readyForSettlement)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Connect once to load your budget history before closing days.',
              ),
            ),
          if (ledger.hasPendingWrites || _controller.saving)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Saved on this phone · waiting to sync',
                style: TextStyle(fontSize: 12),
              ),
            )
          else if (ledger.isFromCache)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Using saved data from this phone',
                style: TextStyle(fontSize: 12),
              ),
            ),
          if (plan == null)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set your daily spending target',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track today’s spending and save unused money to your wallet.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _controller.canAct ? _editLimit : null,
                      child: const Text('Set daily target'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            BalanceCard(
              daily: plan.today,
              onEditLimit: _controller.canAct && plan.unsettledCount == 0
                  ? _editLimit
                  : null,
            ),
            if (plan.unsettledCount > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Review previous days to finalize today’s limit. '
                'Until then, uncovered overspend is carried forward.',
              ),
              OutlinedButton.icon(
                onPressed: _controller.canAct ? _review : null,
                icon: const Icon(Icons.event_available_outlined),
                label: Text('Review ${plan.unsettledCount} previous day(s)'),
              ),
            ],
          ],
          const SizedBox(height: 16),
          FundsSummary(
            ledger: ledger,
            today: _controller.clock(),
            onAccounts: _controller.canAct ? _accounts : null,
            onDebts: _controller.canAct ? _debts : null,
          ),
          TextButton.icon(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) =>
                  SettlementHistorySheet(settlements: ledger.settlements),
            ),
            icon: const Icon(Icons.history),
            label: const Text('Closed days'),
          ),
        ],
      );
    },
  );
}
