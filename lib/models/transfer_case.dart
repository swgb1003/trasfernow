import 'transfer_status.dart';
import 'club.dart';

/// A single reported source backing a [TransferCase] or [TimelineEvent].
/// See SPEC.md §12 情報源管理
class TransferSource {
  const TransferSource({required this.name, this.reliability});

  final String name;

  /// Optional 0-1 reliability score, used for §25 信頼度分析.
  final double? reliability;
}

/// One entry in a transfer case's history. See SPEC.md §7 移籍タイムライン
class TimelineEvent {
  const TimelineEvent({
    required this.date,
    required this.status,
    required this.description,
    required this.source,
  });

  final DateTime date;
  final TransferStatus status;
  final String description;
  final TransferSource source;
}

/// The central data structure of the app. See SPEC.md §26 データ構造
class TransferCase {
  const TransferCase({
    required this.id,
    required this.playerName,
    required this.playerCountryFlag,
    required this.playerAge,
    required this.playerPosition,
    this.playerImageUrl,
    required this.fromClub,
    required this.toClub,
    required this.status,
    required this.probability,
    required this.estimatedFeeMillionsEur,
    required this.lastUpdated,
    required this.sources,
    required this.timeline,
    required this.headline,
  });

  final String id;
  final String playerName;
  final String playerCountryFlag;
  final int playerAge;
  final String playerPosition;

  /// Nullable until a licensed player-image provider is connected.
  final String? playerImageUrl;
  final Club fromClub;
  final Club toClub;
  final TransferStatus status;

  /// Estimated likelihood of completion, 0-100. Explicitly an estimate,
  /// not a fact — see SPEC.md §9.
  final int probability;
  final double estimatedFeeMillionsEur;
  final DateTime lastUpdated;
  final List<TransferSource> sources;
  final List<TimelineEvent> timeline;

  /// Latest headline shown in LIVE feed cards, e.g. "Chelseaが正式オファーを提出".
  final String headline;

  String get route => '${fromClub.name} → ${toClub.name}';

  String get probabilityLabel => switch (probability) {
    >= 100 => 'OFFICIAL',
    >= 85 => '成立間近',
    >= 60 => '移籍の可能性が高まっています',
    >= 35 => '交渉の可能性あり',
    _ => '噂レベル',
  };
}
