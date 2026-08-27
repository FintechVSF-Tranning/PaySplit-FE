import 'package:equatable/equatable.dart';

import '../../../../core/utils/currency_formatter.dart';

class HomeGroupItemEntity extends Equatable {
  const HomeGroupItemEntity({
    required this.id,
    required this.name,
    required this.currency,
    required this.callerRole,
    required this.activeMemberCount,
    this.billSubmissionLocked = false,
    this.emoji = '🍜',
    this.balanceText = '0 đ',
    this.isPositive = false,
    this.isNeutral = true,
  });

  final String id;
  final String name;
  final String currency;
  final String callerRole;
  final int activeMemberCount;
  final bool billSubmissionLocked;
  final String emoji;
  final String balanceText;
  final bool isPositive;
  final bool isNeutral;

  bool get isCaptain => callerRole == 'captain';

  factory HomeGroupItemEntity.fromJson(Map<String, dynamic> json) {
    final group = json['group'] as Map<String, dynamic>? ?? json;
    final name = group['name'] as String? ?? 'Nhóm chi tiêu';
    final role = json['caller_role'] as String? ?? 'member';

    final rawBalance = json['caller_net_balance'];
    final int netBalance;
    if (rawBalance is num) {
      netBalance = rawBalance.toInt();
    } else if (rawBalance != null) {
      netBalance = int.tryParse(rawBalance.toString()) ?? 0;
    } else {
      netBalance = 0;
    }

    final String balanceText;
    final bool isPositive;
    final bool isNeutral;

    if (netBalance > 0) {
      balanceText = '+${CurrencyFormatter.vnd(netBalance)}';
      isPositive = true;
      isNeutral = false;
    } else if (netBalance < 0) {
      balanceText = '-${CurrencyFormatter.vnd(netBalance.abs())}';
      isPositive = false;
      isNeutral = false;
    } else {
      balanceText = '0 đ';
      isPositive = false;
      isNeutral = true;
    }

    return HomeGroupItemEntity(
      id: group['id'] as String? ?? '',
      name: name,
      currency: group['currency'] as String? ?? 'VND',
      callerRole: role,
      activeMemberCount: json['active_member_count'] as int? ?? 1,
      billSubmissionLocked: group['bill_submission_locked'] as bool? ?? false,
      emoji: _pickEmojiForGroupName(name),
      balanceText: balanceText,
      isPositive: isPositive,
      isNeutral: isNeutral,
    );
  }

  static String _pickEmojiForGroupName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ăn') || lower.contains('cơm') || lower.contains('lẩu') || lower.contains('phở')) {
      return '🍜';
    } else if (lower.contains('du lịch') || lower.contains('trip') || lower.contains('đà lạt') || lower.contains('biển')) {
      return '🏖';
    } else if (lower.contains('trọ') || lower.contains('nhà') || lower.contains('room')) {
      return '🏠';
    } else if (lower.contains('công ty') || lower.contains('dev') || lower.contains('team') || lower.contains('dự án')) {
      return '💻';
    } else if (lower.contains('cafe') || lower.contains('cà phê') || lower.contains('trà sữa')) {
      return '☕';
    }
    final emojis = ['🍜', '🏖', '🏠', '💻', '🍻', '🎉', '🍕', '☕'];
    return emojis[name.hashCode.abs() % emojis.length];
  }

  @override
  List<Object?> get props => [id, name, currency, callerRole, activeMemberCount, billSubmissionLocked];
}
