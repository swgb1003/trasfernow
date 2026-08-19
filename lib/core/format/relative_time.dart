String relativeTimeLabel(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'たった今';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
  if (diff.inHours < 24) return '${diff.inHours}時間前';
  return '${diff.inDays}日前';
}

String dateLabel(DateTime dateTime) => '${dateTime.month}/${dateTime.day}';
