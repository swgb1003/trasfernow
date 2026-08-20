import '../models/transfer_case.dart';

/// A rule-based stand-in for the AI移籍記者 (SPEC.md §10).
///
/// This does NOT call any LLM — it pattern-matches the user's Japanese
/// question against the dummy [TransferCase] list and composes a canned
/// response, purely so the chat UI has something real to react to while
/// the UI-first phase (SPEC.md §36) is still ahead of backend/AI wiring.
class AiReporterEngine {
  const AiReporterEngine(this.cases);

  final List<TransferCase> cases;

  String answer(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return '質問を入力してください。';

    final matchedClub = _matchClub(query);
    final matchedPlayer = _matchPlayer(query);

    if (matchedPlayer != null) {
      return _describeCase(matchedPlayer);
    }

    if (matchedClub != null && _mentionsOut(query)) {
      return _describeClubOut(matchedClub);
    }

    if (matchedClub != null && _mentionsPosition(query) != null) {
      return _describeClubPositionIn(matchedClub, _mentionsPosition(query)!);
    }

    if (matchedClub != null) {
      return _describeClubToday(matchedClub);
    }

    if (_mentionsBiggest(query)) {
      return _describeBiggestFee();
    }

    if (query.contains('本当') || query.contains('可能性')) {
      return '成立可能性はあくまで情報源の数・信頼度・交渉の進み具合から算出した推定値です。'
          '客観的な事実ではないので、目安として捉えてください。詳しく知りたい案件があれば選手名かクラブ名で聞いてください。';
    }

    return _describeOverallToday();
  }

  String? _matchClub(String query) {
    final clubs = <String>{};
    for (final c in cases) {
      clubs.add(c.fromClub.name);
      clubs.add(c.toClub.name);
    }
    for (final club in clubs) {
      if (query.contains(club.toLowerCase())) return club;
    }
    return null;
  }

  TransferCase? _matchPlayer(String query) {
    for (final c in cases) {
      final parts = c.playerName.toLowerCase().split(' ');
      if (query.contains(c.playerName.toLowerCase()) ||
          parts.any((p) => p.length > 2 && query.contains(p))) {
        return c;
      }
    }
    return null;
  }

  bool _mentionsOut(String query) =>
      query.contains('退団') ||
      query.contains('出て') ||
      query.contains('去る') ||
      query.contains('out');

  String? _mentionsPosition(String query) {
    const map = {
      'fw': 'FW',
      'フォワード': 'FW',
      'mf': 'MF',
      'ミッドフィルダー': 'MF',
      'df': 'CB',
      'cb': 'CB',
      'ディフェンダー': 'CB',
      'gk': 'GK',
      'ゴールキーパー': 'GK',
    };
    for (final entry in map.entries) {
      if (query.contains(entry.key)) return entry.value;
    }
    return null;
  }

  bool _mentionsBiggest(String query) =>
      (query.contains('一番') || query.contains('最も')) &&
      (query.contains('デカ') || query.contains('大き') || query.contains('高額'));

  String _describeCase(TransferCase c) {
    return '${c.playerName}（${c.fromClub.name} → ${c.toClub.name}）は現在「${c.status.label}」の段階です。\n'
        '${c.headline}。推定成立可能性は${c.probability}%、推定移籍金は€${c.estimatedFeeMillionsEur.toStringAsFixed(0)}mです。';
  }

  String _describeClubOut(String club) {
    final outCases =
        cases.where((c) => c.fromClub.name == club).toList()
          ..sort((a, b) => b.probability.compareTo(a.probability));
    if (outCases.isEmpty) {
      return '現在$clubから退団しそうな選手の案件は確認できません。';
    }
    final lines = outCases
        .take(3)
        .map(
          (c) => '・${c.playerName}（→ ${c.toClub.name}、成立可能性${c.probability}%）',
        )
        .join('\n');
    return '$clubから退団の可能性がある選手は${outCases.length}件あります。\n$lines';
  }

  String _describeClubPositionIn(String club, String position) {
    final inCases =
        cases
            .where((c) => c.toClub.name == club && c.playerPosition == position)
            .toList()
          ..sort((a, b) => b.probability.compareTo(a.probability));
    if (inCases.isEmpty) {
      return '$clubが狙っている$positionの選手は現在確認できません。';
    }
    final lines = inCases
        .map(
          (c) =>
              '・${c.playerName}（${c.fromClub.name}より、成立可能性${c.probability}%）',
        )
        .join('\n');
    return '$clubが獲得を検討している$positionの選手は以下の通りです。\n$lines';
  }

  String _describeClubToday(String club) {
    final relevant =
        cases
            .where((c) => c.fromClub.name == club || c.toClub.name == club)
            .toList()
          ..sort((a, b) => b.probability.compareTo(a.probability));
    if (relevant.isEmpty) {
      return '$clubに関係する移籍案件は現在確認できません。';
    }
    final top = relevant.first;
    final direction = top.toClub.name == club ? 'の獲得交渉' : 'の退団交渉';
    return '$clubに関係する移籍案件は${relevant.length}件動いています。\n'
        '最も進展しているのは${top.playerName}$directionです。${top.headline}。'
        '現在の推定成立可能性は${top.probability}%です。';
  }

  String _describeBiggestFee() {
    final sorted = [...cases]..sort(
      (a, b) => b.estimatedFeeMillionsEur.compareTo(a.estimatedFeeMillionsEur),
    );
    final top = sorted.first;
    return '現在推定移籍金が最も大きいのは${top.playerName}（${top.fromClub.name} → ${top.toClub.name}）で、'
        '約€${top.estimatedFeeMillionsEur.toStringAsFixed(0)}mと見られています。'
        '現在のステータスは「${top.status.label}」、成立可能性は${top.probability}%です。';
  }

  String _describeOverallToday() {
    final sorted = [...cases]
      ..sort((a, b) => b.probability.compareTo(a.probability));
    final breaking = sorted.take(3).toList();
    final lines = breaking
        .asMap()
        .entries
        .map(
          (e) =>
              '${e.key + 1}. ${e.value.playerName}への${e.value.status.label}'
              '（成立可能性${e.value.probability}%）',
        )
        .join('\n');
    return '現在動いている移籍案件は${cases.length}件あります。\n$lines\n\n'
        '気になるクラブ名や選手名を聞いてもらえれば、詳しくお答えします。';
  }
}
