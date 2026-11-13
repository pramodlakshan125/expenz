import 'package:expenz/models/savings_goal.dart';
import 'package:expenz/services/budget_controller.dart';
import 'package:expenz/services/budget_repository.dart';
import 'package:expenz/widgets/home/savings_transfer_sheet.dart';
import 'package:flutter/material.dart';
import 'create_goal_sheet.dart';
import 'goal_card.dart';

class GoalsSection extends StatefulWidget {
  final bool preview;
  final VoidCallback? onSeeMore;
  final BudgetRepository? repository;
  const GoalsSection({
    super.key,
    this.preview = false,
    this.onSeeMore,
    this.repository,
  });
  @override
  State<GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends State<GoalsSection> {
  late final BudgetController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BudgetController(
      repository: widget.repository ?? FirestoreBudgetRepository(),
    )..start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CreateGoalSheet(controller: _controller),
    );
    if (saved == true && mounted) _message('Goal saved on this phone.');
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _transfer(SavingsGoal goal) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SavingsTransferSheet(
        controller: _controller,
        toGoal: true,
        initialGoalId: goal.id,
      ),
    );
    if (saved == true && mounted) {
      _message('Wallet transfer saved on this phone.');
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final ledger = _controller.ledger;
      final goals = [...?ledger?.goals]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Savings goals',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              if (widget.preview)
                TextButton(
                  onPressed: widget.onSeeMore,
                  child: const Text('See more'),
                )
              else
                TextButton.icon(
                  onPressed: _controller.canAct ? _create : null,
                  icon: const Icon(Icons.add),
                  label: const Text('New goal'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_controller.error != null) ...[
            const Text('Could not load or sync savings. Please retry.'),
            TextButton(
              onPressed: _controller.retry,
              child: const Text('Retry'),
            ),
          ] else if (ledger == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (!widget.preview &&
                (ledger.hasPendingWrites || _controller.saving))
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Saved on this phone · waiting to sync'),
              ),
            if (!ledger.readyForSettlement && !widget.preview)
              const Text('Connect once to load your complete savings history.'),
            if (goals.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.flag_rounded, size: 36),
                      const SizedBox(height: 10),
                      const Text('Save for something that matters'),
                      TextButton(
                        onPressed: widget.preview
                            ? widget.onSeeMore
                            : _controller.canAct
                            ? _create
                            : null,
                        child: const Text('Create a goal'),
                      ),
                    ],
                  ),
                ),
              ),
            for (final goal in goals.take(widget.preview ? 2 : goals.length))
              GoalCard(
                goal: goal,
                savedMinor: ledger.goalSavedMinor(goal),
                showTransfer: !widget.preview,
                onTransfer: _controller.canAct ? () => _transfer(goal) : null,
              ),
            if (!widget.preview) const SizedBox(height: 80),
          ],
        ],
      );
    },
  );
}
