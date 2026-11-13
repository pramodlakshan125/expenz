/// The user's daily spending target and the first day it applies.
///
/// Money is stored in minor units: Rs. 500.00 is 50,000 cents. Using integers
/// keeps wallet transfers and splitting overspend accurate to the cent.
/// Firestore conversion belongs in the service, not in this model.
class DailyBudgetSettings {
  final int dailyLimitMinor;

  /// Local calendar date. Days before this date must not earn wallet savings.
  final DateTime startDate;

  DailyBudgetSettings({
    required this.dailyLimitMinor,
    required DateTime startDate,
  }) : startDate = _localDay(startDate) {
    if (dailyLimitMinor < 0) {
      throw ArgumentError.value(
        dailyLimitMinor,
        'dailyLimitMinor',
        'The daily spending limit cannot be negative.',
      );
    }
  }

  static DateTime _localDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
