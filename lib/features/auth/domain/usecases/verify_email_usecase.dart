import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

@injectable
class VerifyEmailUseCase implements UseCase<void, VerifyEmailParams> {
  VerifyEmailUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(VerifyEmailParams params) {
    return _repository.verifyEmail(email: params.email, otp: params.otp);
  }
}

class VerifyEmailParams extends Equatable {
  const VerifyEmailParams({required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  List<Object?> get props => [email, otp];
}
