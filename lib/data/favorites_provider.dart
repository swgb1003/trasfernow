import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'club_catalog.dart';
import 'firebase_service_providers.dart';
import 'shared_preferences_provider.dart';
import 'user_preferences_repository.dart';

/// お気に入りクラブ / お気に入り選手. See SPEC.md §13, §14.
///
/// Persisted locally via [SharedPreferences] and mirrored to the authenticated
/// user's Firestore preferences. "お気に入り選手" is tracked per case rather
/// than per player name, since a TransferCase is the only unit of "player"
/// identity this dummy-data phase models.
class FavoritesState {
  const FavoritesState({required this.clubs, required this.playerCaseIds});

  final Set<String> clubs;
  final Set<String> playerCaseIds;
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier(this._prefs, this._cloud) : super(_load(_prefs)) {
    initializationComplete = _initializeCloud();
  }

  final SharedPreferences _prefs;
  final UserPreferencesRepository? _cloud;
  late final Future<void> initializationComplete;
  int _revision = 0;

  static const _clubsKey = 'favorites.clubs';
  static const _playerCaseIdsKey = 'favorites.playerCaseIds';

  String get _syncMarkerKey => 'cloudSync.favorites.${_cloud!.userId}';

  String get _pendingKey => 'cloudSync.favorites.pending.${_cloud!.userId}';

  static FavoritesState _load(SharedPreferences prefs) {
    final clubs = prefs.getStringList(_clubsKey);
    final playerCaseIds = prefs.getStringList(_playerCaseIdsKey);

    // Nothing saved yet (first launch) → seed with demo favorites so the
    // app isn't empty out of the box. Once the user makes any change,
    // both lists get written and this branch never applies again.
    if (clubs == null && playerCaseIds == null) {
      return const FavoritesState(
        clubs: {'Chelsea', 'Arsenal', 'Man Utd'},
        playerCaseIds: {
          'garnacho-chelsea',
          'osimhen-arsenal',
          'olise-crystal-palace',
        },
      );
    }

    return FavoritesState(
      clubs: (clubs ?? const []).toSet(),
      playerCaseIds: (playerCaseIds ?? const []).toSet(),
    );
  }

  bool get _hasExplicitLocalData =>
      _prefs.containsKey(_clubsKey) || _prefs.containsKey(_playerCaseIdsKey);

  Future<void> _persistLocal() async {
    await _prefs.setStringList(_clubsKey, state.clubs.toList()..sort());
    await _prefs.setStringList(
      _playerCaseIdsKey,
      state.playerCaseIds.toList()..sort(),
    );
  }

  Future<void> _initializeCloud() async {
    final cloud = _cloud;
    if (cloud == null) return;

    final revisionBeforeLoad = _revision;
    final synchronizedBefore = _prefs.getBool(_syncMarkerKey) ?? false;
    final hasPendingChanges =
        _prefs.getBool(_pendingKey) ??
        (!synchronizedBefore && _hasExplicitLocalData);

    if (hasPendingChanges) {
      if (!synchronizedBefore && _hasExplicitLocalData) {
        await _mergeCloud();
      } else {
        await _pushCloud();
      }
      return;
    }

    try {
      final remote = await cloud.loadFavorites();
      if (!mounted) return;
      if (_revision != revisionBeforeLoad) {
        await _pushCloud();
        return;
      }
      if (remote == null) {
        await _pushCloud();
        return;
      }

      state = FavoritesState(
        clubs: remote.clubs,
        playerCaseIds: remote.playerCaseIds,
      );
      await _persistLocal();
      await _markSynchronized();
    } catch (error) {
      debugPrint('Favorite cloud restore failed; keeping local data: $error');
    }
  }

  Future<void> _pushCloud() async {
    final cloud = _cloud;
    if (cloud == null) return;
    final revision = _revision;
    final snapshot = FavoritePreferencesData(
      clubs: {...state.clubs},
      playerCaseIds: {...state.playerCaseIds},
    );
    await _prefs.setBool(_pendingKey, true);
    try {
      await cloud.saveFavorites(snapshot);
      if (revision == _revision) await _markSynchronized();
    } catch (error) {
      debugPrint(
        'Favorite cloud sync failed; local changes are pending: $error',
      );
    }
  }

  Future<void> _mergeCloud() async {
    final cloud = _cloud;
    if (cloud == null) return;
    final revision = _revision;
    final snapshot = FavoritePreferencesData(
      clubs: {...state.clubs},
      playerCaseIds: {...state.playerCaseIds},
    );
    await _prefs.setBool(_pendingKey, true);
    try {
      final merged = await cloud.mergeFavorites(snapshot);
      if (!mounted) return;
      state = FavoritesState(
        clubs: {...merged.clubs, if (revision != _revision) ...state.clubs},
        playerCaseIds: {
          ...merged.playerCaseIds,
          if (revision != _revision) ...state.playerCaseIds,
        },
      );
      await _persistLocal();
      if (revision == _revision) {
        await _markSynchronized();
      } else {
        await _pushCloud();
      }
    } catch (error) {
      debugPrint(
        'Favorite cloud merge failed; local changes are pending: $error',
      );
    }
  }

  Future<void> _markSynchronized() async {
    await _prefs.setBool(_syncMarkerKey, true);
    await _prefs.setBool(_pendingKey, false);
  }

  Future<void> _persistAndSync() async {
    await _persistLocal();
    await _pushCloud();
  }

  /// Explicit retry hook for lifecycle/resume integration and tests.
  Future<void> synchronize() => _pushCloud();

  void _didChange() {
    _revision += 1;
    if (_cloud != null) unawaited(_prefs.setBool(_pendingKey, true));
    unawaited(_persistAndSync());
  }

  void toggleClub(String club) {
    final clubs = {...state.clubs};
    if (!clubs.remove(club)) clubs.add(club);
    state = FavoritesState(clubs: clubs, playerCaseIds: state.playerCaseIds);
    _didChange();
  }

  /// Adds an onboarding choice without accidentally toggling an existing
  /// seeded favorite off. See SPEC.md §13, §20.
  void addClub(String club) {
    if (state.clubs.contains(club)) return;
    state = FavoritesState(
      clubs: {...state.clubs, club},
      playerCaseIds: state.playerCaseIds,
    );
    _didChange();
  }

  void togglePlayerCase(String caseId) {
    final ids = {...state.playerCaseIds};
    if (!ids.remove(caseId)) ids.add(caseId);
    state = FavoritesState(clubs: state.clubs, playerCaseIds: ids);
    _didChange();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>(
      (ref) => FavoritesNotifier(
        ref.watch(sharedPreferencesProvider),
        ref.watch(userPreferencesRepositoryProvider),
      ),
    );

/// All clubs appearing in the dummy dataset (as either origin or
/// destination), for the "クラブを追加" picker.
final allClubsProvider = Provider<List<String>>((ref) {
  final list =
      ClubCatalog.all.map((club) => club.name).toSet().toList()..sort();
  return list;
});
