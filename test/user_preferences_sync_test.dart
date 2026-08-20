import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:transfer_now/data/favorites_provider.dart';
import 'package:transfer_now/data/notification_settings_provider.dart';
import 'package:transfer_now/data/user_preferences_repository.dart';

void main() {
  test('existing local favorites migrate to Firestore on first sync', () async {
    SharedPreferences.setMockInitialValues({
      'favorites.clubs': ['Liverpool'],
      'favorites.playerCaseIds': ['isak-liverpool'],
    });
    final prefs = await SharedPreferences.getInstance();
    final cloud = _FakeUserPreferencesRepository(
      favorites: const FavoritePreferencesData(
        clubs: {'Chelsea'},
        playerCaseIds: {'garnacho-chelsea'},
      ),
    );
    final notifier = FavoritesNotifier(prefs, cloud);

    await notifier.initializationComplete;

    expect(cloud.favoriteLoads, 0);
    expect(cloud.favoriteMerges, 1);
    expect(cloud.favorites?.clubs, {'Chelsea', 'Liverpool'});
    expect(cloud.favorites?.playerCaseIds, {
      'garnacho-chelsea',
      'isak-liverpool',
    });
    expect(notifier.state.clubs, {'Chelsea', 'Liverpool'});
    expect(prefs.getBool('cloudSync.favorites.test-user'), isTrue);
    expect(prefs.getBool('cloudSync.favorites.pending.test-user'), isFalse);
    notifier.dispose();
  });

  test(
    'cloud favorites restore into a device without explicit local data',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cloud = _FakeUserPreferencesRepository(
        favorites: const FavoritePreferencesData(
          clubs: {'PSG'},
          playerCaseIds: {'kvaratskhelia-psg'},
        ),
      );
      final notifier = FavoritesNotifier(prefs, cloud);

      await notifier.initializationComplete;

      expect(cloud.favoriteLoads, 1);
      expect(notifier.state.clubs, {'PSG'});
      expect(notifier.state.playerCaseIds, {'kvaratskhelia-psg'});
      expect(prefs.getStringList('favorites.clubs'), ['PSG']);
      notifier.dispose();
    },
  );

  test(
    'cloud notification settings restore and remain locally cached',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cloud = _FakeUserPreferencesRepository(
        notifications: const NotificationPreferencesData(
          breaking: false,
          agreement: true,
          official: false,
          followedOnly: true,
        ),
      );
      final notifier = NotificationSettingsNotifier(prefs, cloud);

      await notifier.initializationComplete;

      expect(notifier.state.breaking, isFalse);
      expect(notifier.state.agreement, isTrue);
      expect(notifier.state.official, isFalse);
      expect(notifier.state.followedOnly, isTrue);
      expect(prefs.getBool('notifications.breaking'), isFalse);
      expect(prefs.getBool('notifications.followedOnly'), isTrue);
      notifier.dispose();
    },
  );

  test('failed cloud writes remain pending and can be retried', () async {
    SharedPreferences.setMockInitialValues({'notifications.breaking': false});
    final prefs = await SharedPreferences.getInstance();
    final cloud = _FakeUserPreferencesRepository()..failWrites = true;
    final notifier = NotificationSettingsNotifier(prefs, cloud);

    await notifier.initializationComplete;
    expect(prefs.getBool('cloudSync.notifications.pending.test-user'), isTrue);

    cloud.failWrites = false;
    await notifier.synchronize();

    expect(cloud.notifications?.breaking, isFalse);
    expect(cloud.notifications?.agreement, isTrue);
    expect(prefs.getBool('cloudSync.notifications.pending.test-user'), isFalse);
    notifier.dispose();
  });

  test(
    'preference decoders reject malformed notifications and clean lists',
    () {
      final favorites = FavoritePreferencesData.fromFirestore({
        'clubs': [' Chelsea ', '', 42],
        'playerCaseIds': ['case-1', null],
      });
      expect(favorites?.clubs, {'Chelsea'});
      expect(favorites?.playerCaseIds, {'case-1'});

      expect(
        () => NotificationPreferencesData.fromFirestore({
          'breaking': 'yes',
          'agreement': true,
          'official': true,
          'followedOnly': false,
        }),
        throwsFormatException,
      );
    },
  );
}

class _FakeUserPreferencesRepository implements UserPreferencesRepository {
  _FakeUserPreferencesRepository({this.favorites, this.notifications});

  FavoritePreferencesData? favorites;
  NotificationPreferencesData? notifications;
  bool failWrites = false;
  int favoriteLoads = 0;
  int favoriteMerges = 0;

  @override
  String get userId => 'test-user';

  @override
  Future<FavoritePreferencesData?> loadFavorites() async {
    favoriteLoads += 1;
    return favorites;
  }

  @override
  Future<NotificationPreferencesData?> loadNotifications() async {
    return notifications;
  }

  @override
  Future<FavoritePreferencesData> mergeFavorites(
    FavoritePreferencesData data,
  ) async {
    if (failWrites) throw StateError('offline');
    favoriteMerges += 1;
    favorites = FavoritePreferencesData(
      clubs: {...?favorites?.clubs, ...data.clubs},
      playerCaseIds: {...?favorites?.playerCaseIds, ...data.playerCaseIds},
    );
    return favorites!;
  }

  @override
  Future<void> saveFavorites(FavoritePreferencesData data) async {
    if (failWrites) throw StateError('offline');
    favorites = FavoritePreferencesData(
      clubs: {...data.clubs},
      playerCaseIds: {...data.playerCaseIds},
    );
  }

  @override
  Future<void> saveNotifications(NotificationPreferencesData data) async {
    if (failWrites) throw StateError('offline');
    notifications = NotificationPreferencesData(
      breaking: data.breaking,
      agreement: data.agreement,
      official: data.official,
      followedOnly: data.followedOnly,
    );
  }
}
