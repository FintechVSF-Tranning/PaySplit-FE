import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paysplit/core/error/failures.dart';
import 'package:paysplit/features/auth/domain/entities/user_entity.dart';
import 'package:paysplit/features/auth/domain/repositories/auth_repository.dart';
import 'package:paysplit/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late LoginUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
  });

  const user = UserEntity(id: '1', name: 'Lam', email: 'lam@paysplit.app');
  const params = LoginParams(email: 'lam@paysplit.app', password: 'secret123');

  test('returns UserEntity when the repository call succeeds', () async {
    when(
      () => repository.login(email: params.email, password: params.password),
    ).thenAnswer((_) async => const Right(user));

    final result = await useCase(params);

    expect(result, const Right<Failure, UserEntity>(user));
    verify(() => repository.login(email: params.email, password: params.password)).called(1);
  });

  test('returns Failure when the repository call fails', () async {
    when(
      () => repository.login(email: params.email, password: params.password),
    ).thenAnswer((_) async => const Left(UnauthorizedFailure('Sai email hoặc mật khẩu')));

    final result = await useCase(params);

    expect(result, const Left<Failure, UserEntity>(UnauthorizedFailure('Sai email hoặc mật khẩu')));
  });
}
