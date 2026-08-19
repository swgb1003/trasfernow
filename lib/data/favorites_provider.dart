import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transfer_case_providers.dart';

/// お気に入りクラブ / お気に入り選手. See SPEC.md §13, §14.
///
/// In-memory only (no persistence / backend yet — SPEC.md §36 開発方針).
/// "お気に入り選手" is tracked per [TransferCase.id] rather than per player
/// name, since a TransferCase is the only unit of "player" identity this
/// dummy-data phase models.
class FavoritesState {
  const FavoritesState({required this.clubs, required this.playerCaseIds});

  final Set<String> clubs;
  final Set<String> playerCaseIds;
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier()
      : super(
          const FavoritesState(
            clubs: {'Chelsea', 'Arsenal', 'Man Utd'},
            playerCaseIds: {
              'garnacho-chelsea',
              'osimhen-arsenal',
              'olise-crystal-palace',
            },
          ),
        );

  void toggleClub(String club) {
    final clubs = {...state.clubs};
    if (!clubs.remove(club)) clubs.add(club);
    state = FavoritesState(clubs: clubs, playerCaseIds: state.playerCaseIds);
  }

  void togglePlayerCase(String caseId) {
    final ids = {...state.playerCaseIds};
    if (!ids.remove(caseId)) ids.add(caseId);
    state = FavoritesState(clubs: state.clubs, playerCaseIds: ids);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>(
  (ref) => FavoritesNotifier(),
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
