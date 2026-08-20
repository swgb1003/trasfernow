import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transfer_case.dart';
import 'firebase_service_providers.dart';
import 'transfer_case_repository.dart';

final transferCaseRepositoryProvider = Provider<TransferCaseRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore == null
      ? const DummyTransferCaseRepository()
      : FirestoreTransferCaseRepository(firestore);
});

/// All known transfer cases, newest update first. See SPEC.md §27, §28.
final transferCasesProvider = StreamProvider<List<TransferCase>>((ref) {
  return ref.watch(transferCaseRepositoryProvider).watchTransferCases();
});

final transferCaseByIdProvider = FutureProvider.family<TransferCase?, String>((
  ref,
  id,
) async {
  final cases = await ref.watch(transferCasesProvider.future);
  for (final c in cases) {
    if (c.id == id) return c;
  }
  return null;
});
