import 'package:equatable/equatable.dart';

class HomeActivityEntity extends Equatable {
  const HomeActivityEntity({
    required this.id,
    required this.groupId,
    required this.actionType,
    required this.description,
    required this.createdAt,
    this.actorName = '',
    this.actorAvatarUrl,
  });

  final String id;
  final String groupId;
  final String actionType;
  final String description;
  final DateTime createdAt;
  final String actorName;
  final String? actorAvatarUrl;

  factory HomeActivityEntity.fromJson(Map<String, dynamic> json, {String? fallbackGroupId}) {
    final actor = json['actor'] as Map<String, dynamic>? ?? {};
    final rawDate = json['created_at'] as String?;
    final createdAt = rawDate != null ? DateTime.tryParse(rawDate) ?? DateTime.now() : DateTime.now();

    return HomeActivityEntity(
      id: json['id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? fallbackGroupId ?? '',
      actionType: json['action_type'] as String? ?? 'activity',
      description: json['description'] as String? ?? 'Hoạt động mới trong nhóm',
      createdAt: createdAt,
      actorName: actor['display_name'] as String? ?? '',
      actorAvatarUrl: actor['avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, groupId, actionType, description, createdAt];
}
