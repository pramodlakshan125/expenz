/// An immutable wallet-to-goal allocation. Its ID matches the wallet withdrawal.
class GoalContribution {
  final String id;
  final String goalId;
  final int amountMinor;
  final DateTime date;

  GoalContribution({
    required this.id,
    required this.goalId,
    required this.amountMinor,
    required this.date,
  }) {
    if (id.isEmpty || goalId.isEmpty || amountMinor <= 0) {
      throw ArgumentError('Invalid goal contribution.');
    }
  }
}
