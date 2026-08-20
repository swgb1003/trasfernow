import '../models/transfer_case.dart';
import '../models/transfer_status.dart';

/// The "原則3点" (現在 / 金額 / 次の動き) shown on the AI要約 card.
/// See SPEC.md §11 AIニュース要約.
class AiSummary {
  const AiSummary({
    required this.current,
    required this.fee,
    required this.nextMove,
  });

  final String current;
  final String fee;
  final String nextMove;
}

/// Rule-based, like [AiReporterEngine] — not a real LLM call. Templates a
/// short Japanese summary from the case's current status rather than
/// actually condensing foreign-language articles (there are none to
/// condense yet; SPEC.md §36 開発方針, still the dummy-data phase).
AiSummary buildAiSummary(TransferCase transferCase) {
  return AiSummary(
    current: _currentText(transferCase),
    fee: _feeText(transferCase),
    nextMove: _nextMoveText(transferCase.status),
  );
}

String _currentText(TransferCase c) {
  final club = c.toClub.name;
  final player = c.playerName;
  return switch (c.status) {
    TransferStatus.rumour => '$clubが$playerの獲得に関心があるとの噂が出ています。',
    TransferStatus.interest => '$clubが$playerを獲得候補としてリストアップしています。',
    TransferStatus.contact => '$clubが$playerの代理人と接触しています。',
    TransferStatus.negotiation => '$clubが$playerの獲得に向けて交渉を進めています。',
    TransferStatus.bid => '$clubが$playerに正式オファーを提出しています。',
    TransferStatus.agreement => '$playerは$clubへの移籍について個人条件で合意しています。',
    TransferStatus.finalStage => '$clubと$playerの交渉が最終段階に入っています。',
    TransferStatus.official => '$playerの$clubへの完全移籍が正式発表されました。',
    TransferStatus.collapsed => '$clubと$playerの交渉は破談したと報じられています。',
  };
}

String _feeText(TransferCase c) {
  if (c.estimatedFeeMillionsEur <= 0) return '移籍金はまだ明らかになっていません。';
  return '推定€${c.estimatedFeeMillionsEur.toStringAsFixed(0)}m程度と見られています。';
}

String _nextMoveText(TransferStatus status) => switch (status) {
  TransferStatus.rumour => '今後、クラブ側の正式な関心表明や代理人との接触に進むかが焦点です。',
  TransferStatus.interest => '代理人や選手側との接触に進む可能性があります。',
  TransferStatus.contact => '条件面の交渉や正式オファー提出に進む可能性があります。',
  TransferStatus.negotiation => '数日以内に正式オファーが提出される可能性があります。',
  TransferStatus.bid => '個人条件での合意に進む可能性があります。',
  TransferStatus.agreement => 'クラブ間交渉が最終段階に入る可能性があります。',
  TransferStatus.finalStage => '数日以内に正式発表される可能性が高まっています。',
  TransferStatus.official => '移籍手続きはすでに完了しています。',
  TransferStatus.collapsed => '今後、別クラブが名乗りを上げるか動向が注目されます。',
};
