import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_provider.dart';
import 'transfer_case_providers.dart';

/// お気に入りクラブ / お気に入り選手. See SPEC.md §13, §14.
///
/// Persisted locally via [SharedPreferences] (no backend yet — SPEC.md §36
/// 開発方針). "お気に入り選手" is tracked per [TransferCase.id] rather than
/// per player name, since a TransferCase is the only unit of "player"
/// identity this dummy-data phase models.
class FavoritesState {
  const FavoritesState({required this.clubs, required this.playerCaseIds});

  final Set<String> clubs;
  final Set<String> playerCaseIds;
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static const _clubsKey = 'favorites.clubs';
  static const _playerCaseIdsKey = 'favorites.playerCaseIds';

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

  Future<void> _persist() async {
    await _prefs.setStringList(_clubsKey, state.clubs.toList());
    await _prefs.setStringList(_playerCaseIdsKey, state.playerCaseIds.toList());
  }

  void toggleClub(String club) {
    final clubs = {...state.clubs};
    if (!clubs.remove(club)) clubs.add(club);
    state = FavoritesState(clubs: clubs, playerCaseIds: state.playerCaseIds);
    _persist();
  }

  void togglePlayerCase(String caseId) {
    final ids = {...state.playerCaseIds};
    if (!ids.remove(caseId)) ids.add(caseId);
    state = FavoritesState(clubs: state.clubs, playerCaseIds: ids);
    _persist();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>(
  (ref) => FavoritesNotifier(ref.watch(sharedPreferencesProvider)),
);

/// All clubs appearing in the dummy dataset (as either origin or
/// destination), for the "クラブを追加" picker.
final allClubsProvider = Provider<List<String>>((ref) {
  final cases = ref.watch(transferCasesProvider);
  final clubs = <String>{};
  for (final c in cases) {
    clubs.add(c.fromClub);
    clubs.add(c.toClub);
  }
  final list = clubs.toList()..sort();
  return list;
});
