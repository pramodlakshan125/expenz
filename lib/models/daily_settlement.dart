enum SettlementAction { savedToWallet, coveredByWallet, carriedForward, none }

/// An immutable record of one closed local calendar day.
///
/// Money is in cents. Firestore conversion and duplicate prevention belong
/// in the service. Changing transactions must not change a closed record.
class DailySettlement {
  final DateTime date;
  final int baseLimitMinor;
  final int adjustedLimitMinor;
  final int spentMinor;
  final SettlementAction action;

  /// Positive for a wallet deposit, negative for a withdrawal, zero otherwise.
  final int walletChangeMinor;
  final int carriedBeforeMinor;
  final int carryAssignedMinor;

  DailySettlement({
    required DateTime date,
    required this.baseLimitMinor,
    required this.adjustedLimitMinor,
    required this.spentMinor,
    required this.action,
    required this.walletChangeMinor,
    required this.carriedBeforeMinor,
    required this.carryAssignedMinor,
  }) : date = _localDay(date) {
    if (baseLimitMinor < 0 ||
        adjustedLimitMinor < 0 ||
        spentMinor < 0 ||
        carriedBeforeMinor < 0 ||
        carryAssignedMinor < 0) {
      throw ArgumentError('Settlement amounts cannot be negative.');
    }
    if (carryAssignedMinor > carriedBeforeMinor ||
        carryAssignedMinor > baseLimitMinor ||
        adjustedLimitMinor != baseLimitMinor - carryAssignedMinor) {
      throw ArgumentError('The adjusted limit must match the assigned debt.');
    }

    final validAction = switch (action) {
      SettlementAction.savedToWallet =>
        leftoverMinor > 0 && walletChangeMinor == leftoverMinor,
      SettlementAction.coveredByWallet =>
        overspentMinor > 0 &&
            walletChangeMinor < 0 &&
            -walletChangeMinor <= overspentMinor,
      SettlementAction.carriedForward =>
        overspentMinor > 0 && walletChangeMinor == 0,
      SettlementAction.none => overspentMinor == 0 && walletChangeMinor == 0,
    };
    if (!validAction) {
      throw ArgumentError('The wallet change does not match the daily action.');
    }
  }

  /// Stable document ID, for example 2026-04-02.
  String get dayKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  int get leftoverMinor =>
      spentMinor < adjustedLimitMinor ? adjustedLimitMinor - spentMinor : 0;

  int get overspentMinor =>
      spentMinor > adjustedLimitMinor ? spentMinor - adjustedLimitMinor : 0;

  /// A partial wallet withdrawal can still leave uncovered overspend.
  int get uncoveredMinor =>
      overspentMinor + (walletChangeMinor < 0 ? walletChangeMinor : 0);

  /// Retained in history even on the last day of the month. The calculator
  /// ignores this amount when calculating a day in a different month.
  int get carriedAfterMinor =>
      carriedBeforeMinor - carryAssignedMinor + uncoveredMinor;

  static DateTime _localDay(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
