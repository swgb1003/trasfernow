import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transfer_case.dart';
import 'dummy_transfer_cases.dart';
import 'firestore_transfer_case_mapper.dart';

/// Data-source boundary for transfer cases. See SPEC.md §27, §36.
abstract interface class TransferCaseRepository {
  Stream<List<TransferCase>> watchTransferCases();
}

/// Offline implementation used until Firebase is configured.
class DummyTransferCaseRepository implements TransferCaseRepository {
  const DummyTransferCaseRepository();

  @override
  Stream<List<TransferCase>> watchTransferCases() {
    final cases = [...dummyTransferCases];
    cases.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return Stream.value(cases);
  }
}

/// Live Firestore implementation. A snapshot update refreshes every feature
/// consuming `transferCasesProvider`. See SPEC.md §27, §28, §36.
class FirestoreTransferCaseRepository implements TransferCaseRepository {
  const FirestoreTransferCaseRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<TransferCase>> watchTransferCases() {
    return _firestore
        .collection('transferCases')
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => FirestoreTransferCaseMapper.fromFirestore(
                  document.id,
                  document.data(),
                ),
              )
              .toList(growable: false),
        );
  }
}
