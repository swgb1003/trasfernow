import '../models/club.dart';
import '../models/transfer_case.dart';
import '../models/transfer_status.dart';

/// Converts the denormalized `transferCases/{id}` Firestore document to the
/// UI domain model. See SPEC.md §24, §26, §27.
class FirestoreTransferCaseMapper {
  const FirestoreTransferCaseMapper._();

  static TransferCase fromFirestore(
    String documentId,
    Map<String, dynamic> json,
  ) {
    final player = _requiredMap(json, 'player');
    final timeline =
        _mapList(json['timeline']).map((row) {
            return TimelineEvent(
              date: _dateTime(row, 'occurredAt'),
              status: TransferStatus.fromDatabaseValue(_string(row, 'status')),
              description: _string(row, 'description'),
              source: _source(_requiredMap(row, 'source')),
            );
          }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return TransferCase(
      id: documentId,
      playerName: _string(player, 'name'),
      playerCountryFlag: _optionalString(player['countryFlag']) ?? '🌍',
      playerAge: _integer(player, 'age'),
      playerPosition: _string(player, 'position'),
      playerImageUrl: _optionalString(player['imageUrl']),
      fromClub: _club(_requiredMap(json, 'fromClub')),
      toClub: _club(_requiredMap(json, 'toClub')),
      status: TransferStatus.fromDatabaseValue(_string(json, 'status')),
      probability: _integer(json, 'probability'),
      estimatedFeeMillionsEur:
          _number(json, 'estimatedFeeMillionsEur').toDouble(),
      lastUpdated: _dateTime(json, 'lastUpdated'),
      sources: _mapList(json['sources']).map(_source).toList(growable: false),
      timeline: timeline,
      headline: _string(json, 'headline'),
    );
  }

  /// Produces a Firestore-compatible document. DateTime values are converted
  /// to native Firestore timestamps by the Flutter/Admin SDKs.
  static Map<String, dynamic> toFirestore(TransferCase transferCase) {
    Map<String, dynamic> clubJson(Club club) => {
      'id': club.id,
      'name': club.name,
      'shortCode': club.shortCode,
      'league': club.league,
      'crestUrl': club.crestUrl,
      'primaryColor': club.primaryColorValue,
      'secondaryColor': club.secondaryColorValue,
    };

    Map<String, dynamic> sourceJson(TransferSource source) => {
      'name': source.name,
      'reliability': source.reliability,
    };

    return {
      'player': {
        'name': transferCase.playerName,
        'countryFlag': transferCase.playerCountryFlag,
        'age': transferCase.playerAge,
        'position': transferCase.playerPosition,
        'imageUrl': transferCase.playerImageUrl,
      },
      'fromClub': clubJson(transferCase.fromClub),
      'toClub': clubJson(transferCase.toClub),
      'status': transferCase.status.databaseValue,
      'probability': transferCase.probability,
      'estimatedFeeMillionsEur': transferCase.estimatedFeeMillionsEur,
      'headline': transferCase.headline,
      'lastUpdated': transferCase.lastUpdated.toUtc(),
      'sources': transferCase.sources.map(sourceJson).toList(growable: false),
      'timeline': [
        for (final event in transferCase.timeline)
          {
            'occurredAt': event.date.toUtc(),
            'status': event.status.databaseValue,
            'description': event.description,
            'source': sourceJson(event.source),
          },
      ],
    };
  }

  static Club _club(Map<String, dynamic> json) {
    return Club(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      shortCode: _string(json, 'shortCode'),
      league: _string(json, 'league'),
      crestUrl: _optionalString(json['crestUrl']),
      primaryColorValue: _integer(json, 'primaryColor'),
      secondaryColorValue: _integer(json, 'secondaryColor'),
    );
  }

  static TransferSource _source(Map<String, dynamic> json) {
    final reliability = json['reliability'];
    return TransferSource(
      name: _string(json, 'name'),
      reliability: reliability is num ? reliability.toDouble() : null,
    );
  }

  static Map<String, dynamic> _requiredMap(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException('$key must be an object');
  }

  static List<Map<String, dynamic>> _mapList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = _optionalString(json[key]);
    if (value == null) throw FormatException('$key must be a string');
    return value;
  }

  static String? _optionalString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value;
  }

  static num _number(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value;
    throw FormatException('$key must be numeric');
  }

  static int _integer(Map<String, dynamic> json, String key) {
    return _number(json, key).toInt();
  }

  static DateTime _dateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }

    // Cloud Firestore's Timestamp exposes `toDate()`. Keeping this mapper free
    // of plugin types makes its contract tests fast and platform-independent.
    try {
      final converted = (value as dynamic).toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Report one stable domain-level format error below.
    }
    throw FormatException('$key must be a Firestore timestamp');
  }
}
