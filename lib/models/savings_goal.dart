class SavingsGoal {
  final String id;
  final String title;
  final int targetMinor;

  /// Preserves amounts saved by older versions of the app.
  final int initialSavedMinor;
  final DateTime createdAt;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetMinor,
    this.initialSavedMinor = 0,
    required this.createdAt,
  }) {
    if (id.isEmpty ||
        title.trim().isEmpty ||
        targetMinor <= 0 ||
        initialSavedMinor < 0) {
      throw ArgumentError('Invalid savings goal.');
    }
  }
}
