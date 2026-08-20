import 'package:flutter_test/flutter_test.dart';

import 'package:transfer_now/core/config/firebase_config.dart';
import 'package:transfer_now/data/dummy_transfer_cases.dart';
import 'package:transfer_now/data/firestore_transfer_case_mapper.dart';
import 'package:transfer_now/models/transfer_status.dart';

void main() {
  test('missing dart-defines keep Firebase disabled', () {
    expect(FirebaseConfig.isConfigured, isFalse);
  });

  test('all dummy cases survive the Firestore document contract', () {
    for (final original in dummyTransferCases) {
      final json = FirestoreTransferCaseMapper.toFirestore(original);
      final mapped = FirestoreTransferCaseMapper.fromFirestore(
        original.id,
        json,
      );

      expect(mapped.id, original.id);
      expect(mapped.playerName, original.playerName);
      expect(mapped.playerImageUrl, isNull);
      expect(mapped.fromClub.id, original.fromClub.id);
      expect(mapped.fromClub.league, original.fromClub.league);
      expect(mapped.toClub.id, original.toClub.id);
      expect(mapped.status, original.status);
      expect(mapped.estimatedFeeMillionsEur, original.estimatedFeeMillionsEur);
      expect(
        mapped.sources.map((source) => source.name),
        containsAll(original.sources.map((source) => source.name)),
      );
      expect(mapped.timeline, hasLength(original.timeline.length));
      if (mapped.timeline.length > 1) {
        expect(
          mapped.timeline.first.date.isBefore(mapped.timeline.last.date),
          isTrue,
        );
      }
    }
  });

  test('every Flutter status round-trips through its database value', () {
    for (final status in TransferStatus.values) {
      expect(TransferStatus.fromDatabaseValue(status.databaseValue), status);
    }
  });

  test('unknown Firestore status fails instead of silently misclassifying', () {
    final original = dummyTransferCases.first;
    final json = FirestoreTransferCaseMapper.toFirestore(original);
    json['status'] = 'made_up_status';

    expect(
      () => FirestoreTransferCaseMapper.fromFirestore(original.id, json),
      throwsA(isA<FormatException>()),
    );
  });
}
