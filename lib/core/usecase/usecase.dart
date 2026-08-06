import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// Every usecase is a single callable: `Type` is the success payload,
/// `Params` is its input. Repositories always return `Either<Failure,
/// Type>` so failures flow to the presentation layer without exceptions
/// crossing architectural boundaries.
abstract class UseCase<ReturnType, Params> {
  Future<Either<Failure, ReturnType>> call(Params params);
}

/// Use for usecases that take no parameters, e.g. `LogoutUseCase`.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
