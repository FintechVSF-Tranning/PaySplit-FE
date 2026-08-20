import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

@injectable
class ResendVerificationUseCase implements UseCase<void, ResendVerificationParams> {
  ResendVerificationUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(ResendVerificationParams params) {
    return _repository.resendVerification(email: params.email);
  }
}

class ResendVerificationParams extends Equatable {
  const ResendVerificationParams({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}
