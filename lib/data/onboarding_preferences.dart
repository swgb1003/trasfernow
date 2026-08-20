import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_provider.dart';

/// Local-only onboarding state. See SPEC.md §20 (screens 01-03).
class OnboardingPreferences {
  const OnboardingPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const completedKey = 'onboarding.completed';
  static const leagueKey = 'onboarding.league';
  static const clubKey = 'onboarding.club';

  bool get isComplete => _prefs.getBool(completedKey) ?? false;
  String? get selectedLeague => _prefs.getString(leagueKey);
  String? get selectedClub => _prefs.getString(clubKey);

  Future<void> complete({
    required String league,
    required String club,
  }) async {
    await _prefs.setString(leagueKey, league);
    await _prefs.setString(clubKey, club);
    await _prefs.setBool(completedKey, true);
  }
}

final onboardingPreferencesProvider = Provider<OnboardingPreferences>((ref) {
  return OnboardingPreferences(ref.watch(sharedPreferencesProvider));
});
