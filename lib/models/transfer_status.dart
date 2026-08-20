import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// See SPEC.md §8 移籍ステータス
enum TransferStatus {
  rumour,
  interest,
  contact,
  negotiation,
  bid,
  agreement,
  finalStage,
  official,
  collapsed;

  String get databaseValue => switch (this) {
    TransferStatus.finalStage => 'final_stage',
    _ => name,
  };

  static TransferStatus fromDatabaseValue(String value) {
    return switch (value) {
      'rumour' => TransferStatus.rumour,
      'interest' => TransferStatus.interest,
      'contact' => TransferStatus.contact,
      'negotiation' => TransferStatus.negotiation,
      'bid' => TransferStatus.bid,
      'agreement' => TransferStatus.agreement,
      'final_stage' => TransferStatus.finalStage,
      'official' => TransferStatus.official,
      'collapsed' => TransferStatus.collapsed,
      _ => throw FormatException('Unknown transfer status: $value'),
    };
  }

  String get label => switch (this) {
    TransferStatus.rumour => '噂',
    TransferStatus.interest => '関心',
    TransferStatus.contact => '接触',
    TransferStatus.negotiation => '交渉',
    TransferStatus.bid => 'オファー',
    TransferStatus.agreement => '合意間近',
    TransferStatus.finalStage => '最終段階',
    TransferStatus.official => '正式発表',
    TransferStatus.collapsed => '破談',
  };

  String get englishLabel => switch (this) {
    TransferStatus.rumour => 'RUMOUR',
    TransferStatus.interest => 'INTEREST',
    TransferStatus.contact => 'CONTACT',
    TransferStatus.negotiation => 'NEGOTIATION',
    TransferStatus.bid => 'BID',
    TransferStatus.agreement => 'AGREEMENT',
    TransferStatus.finalStage => 'FINAL STAGE',
    TransferStatus.official => 'OFFICIAL',
    TransferStatus.collapsed => 'COLLAPSED',
  };

  String get emoji => switch (this) {
    TransferStatus.rumour => '🔵',
    TransferStatus.interest => '👀',
    TransferStatus.contact => '📞',
    TransferStatus.negotiation => '💬',
    TransferStatus.bid => '💰',
    TransferStatus.agreement => '🤝',
    TransferStatus.finalStage => '🔥',
    TransferStatus.official => '✅',
    TransferStatus.collapsed => '❌',
  };

  Color get color => switch (this) {
    TransferStatus.rumour => AppColors.rumour,
    TransferStatus.interest => AppColors.interest,
    TransferStatus.contact => AppColors.contact,
    TransferStatus.negotiation => AppColors.negotiation,
    TransferStatus.bid => AppColors.bid,
    TransferStatus.agreement => AppColors.agreement,
    TransferStatus.finalStage => AppColors.finalStage,
    TransferStatus.official => AppColors.official,
    TransferStatus.collapsed => AppColors.collapsed,
  };
}
