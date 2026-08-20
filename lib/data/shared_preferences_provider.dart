import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Must be overridden with a resolved [SharedPreferences] instance before
/// the app is run — see `main()`, which awaits [SharedPreferences.getInstance]
/// so every provider that persists state can read/write synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope before use',
  );
});
