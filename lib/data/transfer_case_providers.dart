import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transfer_case.dart';
import 'dummy_transfer_cases.dart';

/// All known transfer cases, newest update first.
final transferCasesProvider = Provider<List<TransferCase>>((ref) {
  final cases = [...dummyTransferCases];
  cases.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  return cases;
});

final transferCaseByIdProvider = Provider.family<TransferCase?, String>(
  (ref, id) {
    final cases = ref.watch(transferCasesProvider);
    for (final c in cases) {
      if (c.id == id) return c;
    }
    return null;
  },
);
