import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/group_repository.dart';

/// Chỉ Captain mới được gửi cấu hình ([expiresInHours], [maxUses],
/// [regenerate]); thành viên thường gọi không tham số để dùng lại mã hiện có.
class CreateInviteParams extends Equatable {
  const CreateInviteParams({
    required this.groupId,
    this.expiresInHours,
    this.maxUses,
    this.regenerate,
  });

  final String groupId;
  final int? expiresInHours;
  final int? maxUses;
  final bool? regenerate;

  @override
  List<Object?> get props => [groupId, expiresInHours, maxUses, regenerate];
}

@injectable
class CreateInviteUseCase implements UseCase<GroupInvite, CreateInviteParams> {
  CreateInviteUseCase(this._repository);

  final GroupRepository _repository;

  @override
  Future<Either<Failure, GroupInvite>> call(CreateInviteParams params) => _repository.createInvite(
    params.groupId,
    expiresInHours: params.expiresInHours,
    maxUses: params.maxUses,
    regenerate: params.regenerate,
  );
}
