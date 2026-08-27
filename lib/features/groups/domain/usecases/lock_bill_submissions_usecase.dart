import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/group_repository.dart';

/// Khóa gửi hóa đơn của nhóm (Captain). Sau khi khóa, nhóm không nhận hóa đơn
/// mới; công nợ đang có vẫn thanh toán bình thường. Backend không có đường mở
/// lại nên đây là thao tác một chiều.
@injectable
class LockBillSubmissionsUseCase implements UseCase<DateTime, String> {
  LockBillSubmissionsUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, DateTime>> call(String groupId) =>
      _repository.lockBillSubmissions(groupId);
}
