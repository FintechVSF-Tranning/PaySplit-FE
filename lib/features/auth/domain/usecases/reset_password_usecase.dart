import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

@injectable
class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) {
    return _repository.resetPassword(
      email: params.email,
      otp: params.otp,
      newPassword: params.newPassword,
    );
  }
}

class ResetPasswordParams extends Equatable {
  const ResetPasswordParams({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  final String email;
  final String otp;
  final String newPassword;

  @override
  List<Object?> get props => [email, otp, newPassword];
}
