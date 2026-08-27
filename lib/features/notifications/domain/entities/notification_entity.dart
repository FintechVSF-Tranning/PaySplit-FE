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

  String get displayTitle => _normalizeTitle(type, title);
  String get displayBody => _normalizeBody(type, body);

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

  static String _normalizeTitle(String type, String rawTitle) {
    final lower = rawTitle.toLowerCase().trim();
    if (lower == 'payment proof submitted' || lower.contains('payment proof submitted')) {
      return 'Minh chứng thanh toán mới';
    }
    if (lower == 'paysplit update' || lower.contains('paysplit update')) {
      if (type == 'payment_created') return 'Yêu cầu thanh toán mới';
      return 'Thông báo từ PaySplit';
    }
    if (lower == 'payment confirmed' || lower.contains('payment confirmed')) {
      return 'Thanh toán đã xác nhận';
    }
    if (lower == 'payment rejected' || lower.contains('payment rejected')) {
      return 'Thanh toán bị từ chối';
    }
    if (lower == 'payment reminder' || lower.contains('payment reminder')) {
      return 'Nhắc nhở thanh toán nợ';
    }
    if (lower == 'confirmation reminder' || lower.contains('confirmation reminder')) {
      return 'Nhắc duyệt minh chứng';
    }
    if (lower == 'new bill' || lower == 'created bill') {
      return 'Hóa đơn mới trong nhóm';
    }
    if (lower == 'bill updated' || lower == 'updated bill') {
      return 'Hóa đơn đã cập nhật';
    }
    if (lower == 'group invitation' || lower == 'group invite') {
      return 'Lời mời vào nhóm';
    }
    return rawTitle;
  }

  static String _normalizeBody(String type, String rawBody) {
    final lower = rawBody.toLowerCase().trim();
    if (lower == 'payment created' || lower.contains('payment created')) {
      return 'Đã tạo mã thanh toán VietQR cho khoản nợ.';
    }
    if (lower == 'a payment proof is waiting for your confirmation' ||
        lower.contains('waiting for your confirmation') ||
        lower.contains('payment proof is waiting')) {
      return 'Có minh chứng chuyển tiền mới đang chờ bạn xác nhận.';
    }
    if (lower == 'your payment was confirmed' || lower.contains('payment was confirmed')) {
      return 'Thanh toán của bạn đã được chủ nợ xác nhận thành công.';
    }
    if (lower == 'your payment proof was rejected' || lower.contains('payment proof was rejected')) {
      return 'Minh chứng chuyển tiền bị từ chối. Vui lòng kiểm tra và gửi lại.';
    }
    if (lower == 'you have an outstanding debt to settle' || lower.contains('outstanding debt to settle')) {
      return 'Bạn có khoản nợ chưa thanh toán. Vui lòng kiểm tra và chuyển khoản.';
    }
    if (lower == 'a submitted payment is still waiting for confirmation' ||
        lower.contains('still waiting for confirmation')) {
      return 'Minh chứng thanh toán đã gửi lâu chưa được duyệt. Vui lòng xác nhận.';
    }
    return rawBody;
  }

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    final rawReadAt = json['read_at'] as String?;
    final rawCreatedAt = json['created_at'] as String?;
    final rawPayload = json['payload'];
    final rawType = json['type'] as String? ?? 'general';
    final rawTitle = json['title'] as String? ?? 'Thông báo';
    final rawBody = json['body'] as String? ?? '';

    Map<String, dynamic> payloadMap = {};
    if (rawPayload is Map<String, dynamic>) {
      payloadMap = rawPayload;
    }

    return NotificationEntity(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: rawType,
      title: _normalizeTitle(rawType, rawTitle),
      body: _normalizeBody(rawType, rawBody),
      payload: payloadMap,
      readAt: rawReadAt != null ? DateTime.tryParse(rawReadAt) : null,
      createdAt: rawCreatedAt != null ? DateTime.tryParse(rawCreatedAt) ?? DateTime.now() : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, userId, type, title, body, payload, readAt, createdAt];
}
