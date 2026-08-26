import 'package:dio/dio.dart';

import '../error/failures.dart';

const Map<String, String> _errorMessages = {
  'EMAIL_EXISTS':
      'Địa chỉ email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác.',
  'PHONE_EXISTS': 'Số điện thoại này đã được liên kết với một tài khoản khác.',
  'INVALID_CREDENTIALS':
      'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.',
  'EMAIL_NOT_VERIFIED':
      'Tài khoản chưa được kích hoạt. Vui lòng nhập mã OTP để xác thực.',
  'ACCOUNT_UNAVAILABLE':
      'Tài khoản hiện đang bị khóa hoặc tạm ngưng hoạt động.',
  'INVALID_OR_EXPIRED_TOKEN':
      'Mã OTP không chính xác hoặc đã hết hạn hiệu lực.',
  // 429 không chỉ đến từ "thao tác sai": ngưỡng tính theo IP nên vài người dùng
  // chung một mạng, hay một máy đăng nhập nhiều tài khoản, cũng chạm được. Nói
  // đúng nguyên nhân, kèm thời gian chờ lấy từ header `Retry-After`.
  'RATE_LIMITED':
      'Máy chủ đang nhận quá nhiều yêu cầu từ kết nối của bạn. Vui lòng thử lại sau ít giây.',
  'SESSION_REVOKED': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
  'INVALID_CURRENT_PASSWORD': 'Mật khẩu hiện tại không chính xác.',
  'UNSUPPORTED_BANK': 'Ngân hàng được chọn hiện chưa được hệ thống hỗ trợ.',
  'INVALID_IMAGE': 'Hình ảnh không hợp lệ hoặc không đúng định dạng cho phép.',
  'PAYLOAD_TOO_LARGE':
      'Dung lượng tệp tải lên vượt quá giới hạn cho phép (tối đa 10MB).',
  'IMAGE_STORAGE_FAILED': 'Lỗi lưu trữ hình ảnh, vui lòng thử lại sau.',
  'VALIDATION_FAILED':
      'Dữ liệu nhập vào chưa đúng định dạng. Vui lòng kiểm tra lại.',
  'INTERNAL_ERROR': 'Hệ thống đang gặp sự cố tạm thời, vui lòng thử lại sau.',

  // --- Xác thực ---
  // Backend trả nguyên văn tiếng Anh "authentication required" khi request
  // không mang access token hợp lệ; thiếu mục này thì chuỗi đó lọt thẳng lên
  // giao diện.
  'AUTHENTICATION_REQUIRED': 'Bạn cần đăng nhập để thực hiện thao tác này.',
  'UNAUTHORIZED': 'Bạn cần đăng nhập để thực hiện thao tác này.',
  'FORBIDDEN': 'Bạn không có quyền thực hiện thao tác này.',

  // --- Nhóm (module group) ---
  'GROUP_NOT_FOUND':
      'Không tìm thấy nhóm, hoặc bạn không còn là thành viên.',
  'INVITE_NOT_FOUND':
      'Mã mời không tồn tại, đã bị thu hồi hoặc đã hết hạn. Hãy xin mã mới từ trưởng nhóm.',
  'MEMBER_NOT_FOUND': 'Không tìm thấy thành viên này trong nhóm.',
  'CAPTAIN_REQUIRED': 'Chỉ trưởng nhóm mới được thực hiện thao tác này.',
  'CAPTAIN_TRANSFER_REQUIRED':
      'Bạn đang là trưởng nhóm. Hãy chuyển quyền cho người khác trước khi rời nhóm.',
  'CAPTAIN_TRANSFER_CONFLICT':
      'Quyền trưởng nhóm vừa thay đổi. Hãy tải lại nhóm rồi thử lại.',
  'GROUP_MEMBER_LIMIT_REACHED': 'Nhóm đã đạt số lượng thành viên tối đa.',
  'GROUP_MEMBER_HAS_OPEN_DEBTS':
      'Thành viên này còn công nợ chưa tất toán nên chưa thể rời hoặc bị xóa khỏi nhóm.',
  'GROUP_HAS_UNSETTLED_OBLIGATIONS':
      'Nhóm còn hóa đơn hoặc công nợ chưa xong nên chưa thể giải tán.',
  'BULK_FINALIZE_IN_PROGRESS':
      'Nhóm đang chốt hóa đơn hàng loạt. Vui lòng đợi hoàn tất.',
  'INVALID_CURSOR': 'Dữ liệu phân trang không hợp lệ. Hãy tải lại danh sách.',
};

Failure mapDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure(
        'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng.',
      );
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final code = _extractCode(data);
      final rawMessage = _extractMessage(data);
      final fields = _extractFields(data);

      // If specific fields have error messages, build a clear compound message
      String? fieldDetailMessage;
      if (fields != null && fields.isNotEmpty) {
        final messages = fields.entries
            .map((e) => '${e.key}: ${e.value}')
            .join(', ');
        fieldDetailMessage = 'Lỗi nhập liệu ($messages)';
      }

      var localizedMessage =
          (code != null && _errorMessages.containsKey(code))
          ? _errorMessages[code]!
          : (fieldDetailMessage ??
                rawMessage ??
                'Lỗi từ máy chủ ($statusCode)');

      if (statusCode == 429) {
        final retryAfter = _retryAfterSeconds(error.response);
        if (retryAfter != null) {
          localizedMessage =
              'Máy chủ đang nhận quá nhiều yêu cầu từ kết nối của bạn. '
              'Vui lòng thử lại sau $retryAfter giây.';
        }
      }

      if (statusCode == 401 || statusCode == 403) {
        return UnauthorizedFailure(localizedMessage, code);
      }
      if (statusCode == 422 || statusCode == 400) {
        return ValidationFailure(localizedMessage, code: code, fields: fields);
      }
      return ServerFailure(
        localizedMessage,
        code: code,
        statusCode: statusCode,
      );
    case DioExceptionType.cancel:
      return const UnexpectedFailure('Yêu cầu đã bị hủy', 'REQUEST_CANCELLED');
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
    default:
      return const UnexpectedFailure(
        'Đã có lỗi không mong muốn xảy ra, vui lòng thử lại',
      );
  }
}

/// Số giây chờ do máy chủ chỉ định trong header `Retry-After` của 429.
int? _retryAfterSeconds(Response<dynamic>? response) {
  final raw = response?.headers.value('retry-after');
  if (raw == null) return null;
  final seconds = int.tryParse(raw.trim());
  if (seconds == null || seconds <= 0) return null;
  return seconds;
}

String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    if (data['error'] is Map<String, dynamic>) {
      return (data['error'] as Map<String, dynamic>)['message'] as String?;
    }
    return data['message'] as String? ?? data['error'] as String?;
  }
  return null;
}

String? _extractCode(dynamic data) {
  if (data is Map<String, dynamic>) {
    if (data['error'] is Map<String, dynamic>) {
      return (data['error'] as Map<String, dynamic>)['code'] as String?;
    }
    return data['code'] as String?;
  }
  return null;
}

Map<String, String>? _extractFields(dynamic data) {
  if (data is Map<String, dynamic>) {
    final err = data['error'];
    if (err is Map<String, dynamic>) {
      // BE hiện trả "details"; đọc thêm "fields" (tên cũ) để khoan dung khi
      // BE/FE chưa deploy đồng thời.
      final rawFields = err['details'] ?? err['fields'];
      if (rawFields is Map) {
        return rawFields.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    }
  }
  return null;
}
