import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

@injectable
class UpdateProfileUseCase implements UseCase<UserEntity, UpdateProfileParams> {
  UpdateProfileUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(UpdateProfileParams params) {
    return _repository.updateProfile(
      name: params.name,
      phoneNumber: params.phoneNumber,
      bankCode: params.bankCode,
      bankAccountNumber: params.bankAccountNumber,
      bankAccountHolder: params.bankAccountHolder,
    );
  }
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({
    this.name,
    this.phoneNumber,
    this.bankCode,
    this.bankAccountNumber,
    this.bankAccountHolder,
  });

  final String? name;
  final String? phoneNumber;
  final String? bankCode;
  final String? bankAccountNumber;
  final String? bankAccountHolder;

  @override
  List<Object?> get props => [name, phoneNumber, bankCode, bankAccountNumber, bankAccountHolder];
}
