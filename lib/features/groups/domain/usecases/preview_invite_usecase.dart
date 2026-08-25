import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/group_repository.dart';

@injectable
class PreviewInviteUseCase implements UseCase<GroupInvitePreview, String> {
  PreviewInviteUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, GroupInvitePreview>> call(String code) => _repository.previewInvite(code);
}
