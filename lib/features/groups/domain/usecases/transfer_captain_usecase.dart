import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/group_repository.dart';
import 'leave_or_remove_member_usecase.dart';

@injectable
class TransferCaptainUseCase implements UseCase<Unit, MemberParams> {
  TransferCaptainUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(MemberParams params) =>
      _repository.transferCaptain(params.groupId, params.membershipId);
}
