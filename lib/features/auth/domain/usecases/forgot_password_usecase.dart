import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

@injectable
class ForgotPasswordUseCase implements UseCase<void, ForgotPasswordParams> {
  ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(ForgotPasswordParams params) {
    return _repository.forgotPassword(email: params.email);
  }
}

class ForgotPasswordParams extends Equatable {
  const ForgotPasswordParams({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}
