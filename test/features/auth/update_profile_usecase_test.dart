import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paysplit/core/error/failures.dart';
import 'package:paysplit/features/auth/domain/entities/user_entity.dart';
import 'package:paysplit/features/auth/domain/repositories/auth_repository.dart';
import 'package:paysplit/features/auth/domain/usecases/update_profile_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late UpdateProfileUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = UpdateProfileUseCase(repository);
  });

  const updatedUser = UserEntity(
    id: 'usr-1',
    name: 'Nguyen Van A',
    email: 'user@example.com',
    phoneNumber: '+84123456789',
  );

  const params = UpdateProfileParams(
    name: 'Nguyen Van A',
    phoneNumber: '+84123456789',
  );

  test('returns UserEntity when update profile succeeds', () async {
    when(
      () => repository.updateProfile(
        name: params.name,
        phoneNumber: params.phoneNumber,
        bankCode: params.bankCode,
        bankAccountNumber: params.bankAccountNumber,
        bankAccountHolder: params.bankAccountHolder,
      ),
    ).thenAnswer((_) async => const Right(updatedUser));

    final result = await useCase(params);

    expect(result, const Right<Failure, UserEntity>(updatedUser));
    verify(
      () => repository.updateProfile(
        name: params.name,
        phoneNumber: params.phoneNumber,
        bankCode: params.bankCode,
        bankAccountNumber: params.bankAccountNumber,
        bankAccountHolder: params.bankAccountHolder,
      ),
    ).called(1);
  });

  test('returns Failure when update profile fails', () async {
    when(
      () => repository.updateProfile(
        name: params.name,
        phoneNumber: params.phoneNumber,
        bankCode: params.bankCode,
        bankAccountNumber: params.bankAccountNumber,
        bankAccountHolder: params.bankAccountHolder,
      ),
    ).thenAnswer((_) async => const Left(ServerFailure('Cập nhật thất bại')));

    final result = await useCase(params);

    expect(result, const Left<Failure, UserEntity>(ServerFailure('Cập nhật thất bại')));
  });
}
