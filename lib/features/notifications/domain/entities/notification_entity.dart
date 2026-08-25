import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? payload,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    final rawReadAt = json['read_at'] as String?;
    final rawCreatedAt = json['created_at'] as String?;
    final rawPayload = json['payload'];

    Map<String, dynamic> payloadMap = {};
    if (rawPayload is Map<String, dynamic>) {
      payloadMap = rawPayload;
    }

    return NotificationEntity(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? 'Thông báo',
      body: json['body'] as String? ?? '',
      payload: payloadMap,
      readAt: rawReadAt != null ? DateTime.tryParse(rawReadAt) : null,
      createdAt: rawCreatedAt != null ? DateTime.tryParse(rawCreatedAt) ?? DateTime.now() : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, userId, type, title, body, payload, readAt, createdAt];
}
