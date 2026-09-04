import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/group_repository.dart';

/// Mở khóa nhận hóa đơn mới của nhóm (Captain).
@injectable
class UnlockBillSubmissionsUseCase implements UseCase<Unit, String> {
  UnlockBillSubmissionsUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String groupId) =>
      _repository.unlockBillSubmissions(groupId);
}
