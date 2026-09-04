import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paysplit/core/error/failures.dart';
import 'package:paysplit/features/auth/domain/repositories/auth_repository.dart';
import 'package:paysplit/features/auth/domain/usecases/change_password_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late ChangePasswordUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = ChangePasswordUseCase(repository);
  });

  const params = ChangePasswordParams(
    currentPassword: 'OldPassword1',
    newPassword: 'NewPassword2',
  );

  test('returns Right(null) when change password succeeds', () async {
    when(
      () => repository.changePassword(
        currentPassword: params.currentPassword,
        newPassword: params.newPassword,
      ),
    ).thenAnswer((_) async => const Right(null));

    final result = await useCase(params);

    expect(result, const Right<Failure, void>(null));
    verify(
      () => repository.changePassword(
        currentPassword: params.currentPassword,
        newPassword: params.newPassword,
      ),
    ).called(1);
  });

  test('returns Failure when change password fails', () async {
    when(
      () => repository.changePassword(
        currentPassword: params.currentPassword,
        newPassword: params.newPassword,
      ),
    ).thenAnswer((_) async => const Left(ServerFailure('Mật khẩu hiện tại không chính xác')));

    final result = await useCase(params);

    expect(result, const Left<Failure, void>(ServerFailure('Mật khẩu hiện tại không chính xác')));
  });
}
