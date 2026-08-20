import 'package:cloud_firestore/cloud_firestore.dart';

/// Cloud representation of favorite clubs and transfer cases.
/// See SPEC.md §13, §14, §24, §36.
class FavoritePreferencesData {
  const FavoritePreferencesData({
    required this.clubs,
    required this.playerCaseIds,
  });

  final Set<String> clubs;
  final Set<String> playerCaseIds;

  static FavoritePreferencesData? fromFirestore(Map<String, dynamic>? json) {
    if (json == null) return null;
    return FavoritePreferencesData(
      clubs: _stringSet(json['clubs']),
      playerCaseIds: _stringSet(json['playerCaseIds']),
    );
  }
}

/// Cloud representation of notification categories and audience filtering.
/// See SPEC.md §15, §24, §36.
class NotificationPreferencesData {
  const NotificationPreferencesData({
    required this.breaking,
    required this.agreement,
    required this.official,
    required this.followedOnly,
  });

  final bool breaking;
  final bool agreement;
  final bool official;
  final bool followedOnly;

  static NotificationPreferencesData? fromFirestore(
    Map<String, dynamic>? json,
  ) {
    if (json == null) return null;
    final breaking = json['breaking'];
    final agreement = json['agreement'];
    final official = json['official'];
    final followedOnly = json['followedOnly'];
    if (breaking is! bool ||
        agreement is! bool ||
        official is! bool ||
        followedOnly is! bool) {
      throw const FormatException('Invalid notification preferences');
    }
    return NotificationPreferencesData(
      breaking: breaking,
      agreement: agreement,
      official: official,
      followedOnly: followedOnly,
    );
  }
}

abstract interface class UserPreferencesRepository {
  String get userId;

  Future<FavoritePreferencesData?> loadFavorites();

  Future<void> saveFavorites(FavoritePreferencesData data);

  Future<FavoritePreferencesData> mergeFavorites(FavoritePreferencesData data);

  Future<NotificationPreferencesData?> loadNotifications();

  Future<void> saveNotifications(NotificationPreferencesData data);
}

/// Stores private settings below `users/{uid}/preferences/*`.
/// Client access is restricted to the matching authenticated UID by Rules.
class FirestoreUserPreferencesRepository implements UserPreferencesRepository {
  const FirestoreUserPreferencesRepository({
    required FirebaseFirestore firestore,
    required this.userId,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  final String userId;

  DocumentReference<Map<String, dynamic>> get _favoritesDocument => _firestore
      .collection('users')
      .doc(userId)
      .collection('preferences')
      .doc('favorites');

  DocumentReference<Map<String, dynamic>> get _notificationsDocument =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications');

  @override
  Future<FavoritePreferencesData?> loadFavorites() async {
    final snapshot = await _favoritesDocument.get();
    return FavoritePreferencesData.fromFirestore(snapshot.data());
  }

  @override
  Future<void> saveFavorites(FavoritePreferencesData data) {
    return _favoritesDocument.set({
      'clubs': data.clubs.toList()..sort(),
      'playerCaseIds': data.playerCaseIds.toList()..sort(),
      'schemaVersion': 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<FavoritePreferencesData> mergeFavorites(FavoritePreferencesData data) {
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(_favoritesDocument);
      final existing = FavoritePreferencesData.fromFirestore(snapshot.data());
      final merged = FavoritePreferencesData(
        clubs: {...?existing?.clubs, ...data.clubs},
        playerCaseIds: {...?existing?.playerCaseIds, ...data.playerCaseIds},
      );
      transaction.set(_favoritesDocument, {
        'clubs': merged.clubs.toList()..sort(),
        'playerCaseIds': merged.playerCaseIds.toList()..sort(),
        'schemaVersion': 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return merged;
    });
  }

  @override
  Future<NotificationPreferencesData?> loadNotifications() async {
    final snapshot = await _notificationsDocument.get();
    return NotificationPreferencesData.fromFirestore(snapshot.data());
  }

  @override
  Future<void> saveNotifications(NotificationPreferencesData data) {
    return _notificationsDocument.set({
      'breaking': data.breaking,
      'agreement': data.agreement,
      'official': data.official,
      'followedOnly': data.followedOnly,
      'schemaVersion': 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

Set<String> _stringSet(Object? value) {
  if (value is! List) return <String>{};
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet();
}
