import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Contract implemented by the data layer ([AuthRepositoryImpl]). The
/// domain and presentation layers depend only on this interface, never on
/// the concrete Dio/Retrofit implementation — this is what lets usecases
/// be unit-tested with a fake/mock repository.
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({required String email, required String password});

  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, void>> logout();
}
