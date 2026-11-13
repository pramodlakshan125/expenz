import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expenz/models/daily_budget_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef DailyBudgetSettingsState = ({
  DailyBudgetSettings? settings,
  bool hasPendingWrites,
  bool isFromCache,
});

/// Reads and queues writes for users/{uid}; calculations live elsewhere.
class DailyBudgetSettingsService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  DailyBudgetSettingsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore,
      _auth = auth;

  DocumentReference<Map<String, dynamic>> get _document {
    final user = (_auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) throw StateError('Sign in to manage your daily limit.');
    return (_firestore ?? FirebaseFirestore.instance)
        .collection('users')
        .doc(user.uid);
  }

  /// Includes local edits immediately and reports when they reach the server.
  /// A missing cached setting is not proof that no setting exists online.
  Stream<DailyBudgetSettingsState> watch() => _document
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => (
          settings: _decode(snapshot.data()),
          hasPendingWrites: snapshot.metadata.hasPendingWrites,
          isFromCache: snapshot.metadata.isFromCache,
        ),
      );

  /// Queues a write without waiting for server acknowledgement.
  ///
  /// Callers must show errors through [onError] and use [watch] for pending
  /// status. Returning from this method does not mean a save has synced.
  /// Preserve the existing start date when updating an existing budget.
  void save(
    DailyBudgetSettings settings, {
    required void Function(Object error, StackTrace stackTrace) onError,
  }) {
    final document = _document;
    unawaited(
      document
          .set({
            // Public Firestore field is in rupees; the domain uses cents.
            'dailyLimit': settings.dailyLimitMinor / 100,
            'dailyLimitStartDate': _dateKey(settings.startDate),
          }, SetOptions(merge: true))
          .catchError((Object error, StackTrace stackTrace) {
            onError(error, stackTrace);
          }),
    );
  }

  static DailyBudgetSettings? _decode(Map<String, dynamic>? data) {
    if (data == null || !data.containsKey('dailyLimit')) return null;

    final limit = data['dailyLimit'];
    final start = data['dailyLimitStartDate'];
    if (limit is! num || !limit.isFinite || limit < 0 || start is! String) {
      throw const FormatException('Invalid saved daily budget settings.');
    }
    // Store a calendar date, rather than a timestamp that can change day
    // when the user changes time zones.
    final date = DateTime.tryParse(start);
    if (date == null || _dateKey(date) != start) {
      throw const FormatException('Invalid daily budget start date.');
    }
    return DailyBudgetSettings(
      dailyLimitMinor: (limit * 100).round(),
      startDate: date,
    );
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
