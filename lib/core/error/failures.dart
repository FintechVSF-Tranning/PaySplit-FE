import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures returned via `Either<Failure, T>`.
abstract class Failure extends Equatable {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [message, code, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Không có kết nối mạng', String? code])
    : super(code: code ?? 'NETWORK_ERROR');
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Lỗi bộ nhớ đệm', String? code])
    : super(code: code ?? 'CACHE_ERROR');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Phiên đăng nhập hết hạn', String? code])
    : super(code: code ?? 'UNAUTHORIZED');
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, this.fields});

  final Map<String, String>? fields;

  @override
  List<Object?> get props => [message, code, fields];
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Đã có lỗi xảy ra, vui lòng thử lại', String? code])
    : super(code: code ?? 'UNEXPECTED_ERROR');
}

/// Body 2xx nhưng sai shape so với hợp đồng API: `ApiResponse.requireData` ném
/// [StateError] khi `data` null, hoặc ép kiểu `data` ném [TypeError]. Cả hai
/// đều không phải `DioException` nên repository phải bắt riêng, nếu không
/// exception sẽ thoát ra ngoài thay vì trở thành [Failure].
const Failure invalidResponseFailure = UnexpectedFailure(
  'Máy chủ trả về dữ liệu không hợp lệ. Vui lòng thử lại sau.',
  'INVALID_RESPONSE',
);
