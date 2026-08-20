/// Stable club identity shared by transfer cases and future API responses.
/// See SPEC.md §17, §24, §26.
class Club {
  const Club({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.league,
    required this.primaryColorValue,
    required this.secondaryColorValue,
    this.crestUrl,
  });

  /// Internal stable ID. This can later map to a Football API provider ID.
  final String id;
  final String name;
  final String shortCode;
  final String league;

  /// Nullable until an image provider with suitable usage rights is chosen.
  final String? crestUrl;

  /// Stored as ARGB integers to keep the domain model independent of Flutter.
  final int primaryColorValue;
  final int secondaryColorValue;

  @override
  bool operator ==(Object other) => other is Club && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}
