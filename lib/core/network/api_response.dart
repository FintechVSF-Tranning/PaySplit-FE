/// Vỏ bọc response chuẩn của API: `{"success", "data", "message"}` khi thành
/// công. Dùng class thuần (không dùng freezed) vì [fromJson] cần logic tùy
/// biến để đọc khoan dung cả body kiểu cũ (không có key `success`, coi cả
/// body là `data`) trong lúc BE/FE đang chuyển đổi song song.
class ApiResponse<T> {
  const ApiResponse({required this.success, this.data, this.message});

  final bool success;
  final T? data;
  final String? message;

  /// Giải mã [json] thành [ApiResponse]. [fromJsonT] parse phần `data` (hoặc
  /// toàn bộ body khi body không có key `success`) thành `T`.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    if (!json.containsKey('success')) {
      return ApiResponse<T>(success: true, data: fromJsonT(json));
    }
    final raw = json['data'];
    return ApiResponse<T>(
      success: json['success'] as bool? ?? true,
      data: raw == null ? null : fromJsonT(raw),
      message: json['message'] as String?,
    );
  }

  /// Trả về [data], ném lỗi nếu thiếu. Dùng ở repository cho response bắt
  /// buộc phải có payload.
  T get requireData {
    final value = data;
    if (value == null) {
      throw StateError('ApiResponse.requireData: data is null');
    }
    return value;
  }
}
