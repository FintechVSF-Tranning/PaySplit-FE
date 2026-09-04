import 'package:equatable/equatable.dart';

import '../../../groups/data/models/activity_mapper.dart';

class HomeActivityEntity extends Equatable {
  const HomeActivityEntity({
    required this.id,
    required this.groupId,
    this.groupName = '',
    required this.actionType,
    required this.description,
    required this.createdAt,
    this.actorName = '',
    this.actorAvatarUrl,
    this.billId,
    this.amount,
    this.metadata = const {},
  });

  final String id;
  final String groupId;
  final String groupName;
  final String actionType;
  final String description;
  final DateTime createdAt;
  final String actorName;
  final String? actorAvatarUrl;
  final String? billId;
  final int? amount;
  final Map<String, dynamic> metadata;

  factory HomeActivityEntity.fromJson(
    Map<String, dynamic> json, {
    String? fallbackGroupId,
    String? groupName,
  }) {
    final actor = json['actor'] as Map<String, dynamic>? ?? {};
    final rawDate = json['created_at'] as String?;
    final createdAt = rawDate != null ? DateTime.tryParse(rawDate) ?? DateTime.now() : DateTime.now();

    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final billId = meta['bill_id'] as String?;

    int? parsedAmount;
    if (meta['total'] is num) {
      parsedAmount = (meta['total'] as num).toInt();
    } else if (meta['amount'] is num) {
      parsedAmount = (meta['amount'] as num).toInt();
    }

    final rawDescription = json['description'] as String? ?? 'Hoạt động mới trong nhóm';

    return HomeActivityEntity(
      id: json['id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? fallbackGroupId ?? '',
      groupName: groupName ?? (json['group_name'] as String? ?? ''),
      actionType: json['action_type'] as String? ?? 'activity',
      description: formatActivityTitle(rawDescription),
      createdAt: createdAt,
      actorName: actor['display_name'] as String? ?? '',
      actorAvatarUrl: actor['avatar_url'] as String?,
      billId: billId,
      amount: parsedAmount,
      metadata: meta,
    );
  }

  @override
  List<Object?> get props => [id, groupId, groupName, actionType, description, createdAt, actorName, billId, amount];
}
