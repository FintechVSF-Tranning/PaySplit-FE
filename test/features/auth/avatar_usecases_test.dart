import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:paysplit/core/error/failures.dart';
import 'package:paysplit/core/usecase/usecase.dart';
import 'package:paysplit/features/auth/domain/entities/user_entity.dart';
import 'package:paysplit/features/auth/domain/repositories/auth_repository.dart';
import 'package:paysplit/features/auth/domain/usecases/delete_avatar_usecase.dart';
import 'package:paysplit/features/auth/domain/usecases/upload_avatar_usecase.dart';

class FakeAuthRepository implements AuthRepository {
  bool shouldFail = false;
  String returnedUrl = 'https://res.cloudinary.com/avatar.webp';

  @override
  Future<Either<Failure, String>> uploadAvatar({
    File? avatar,
    List<int>? bytes,
    String? filename,
  }) async {
    if (shouldFail) {
      return const Left(ServerFailure('Upload avatar failed'));
    }
    return Right(returnedUrl);
  }

  @override
  Future<Either<Failure, void>> deleteAvatar() async {
    if (shouldFail) {
      return const Left(ServerFailure('Delete avatar failed'));
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> changePassword({required String currentPassword, required String newPassword}) async => const Right(null);

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async => const Right(null);

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async => const Right(UserEntity(id: '1', name: 'A', email: 'a@a.com'));

  @override
  Future<Either<Failure, UserEntity>> login({required String email, required String password}) async => const Right(UserEntity(id: '1', name: 'A', email: 'a@a.com'));

  @override
  Future<Either<Failure, void>> logout() async => const Right(null);

  @override
  Future<Either<Failure, UserEntity>> register({required String name, required String email, required String password, String? phoneNumber}) async => const Right(UserEntity(id: '1', name: 'A', email: 'a@a.com'));

  @override
  Future<Either<Failure, void>> resendVerification({required String email}) async => const Right(null);

  @override
  Future<Either<Failure, void>> resetPassword({required String email, required String otp, required String newPassword}) async => const Right(null);

  @override
  Future<Either<Failure, UserEntity>> updateProfile({String? name, String? phoneNumber, String? bankCode, String? bankAccountNumber, String? bankAccountHolder}) async => const Right(UserEntity(id: '1', name: 'A', email: 'a@a.com'));

  @override
  Future<Either<Failure, void>> verifyEmail({required String email, required String otp}) async => const Right(null);
}

void main() {
  late FakeAuthRepository repository;
  late UploadAvatarUseCase uploadUseCase;
  late DeleteAvatarUseCase deleteUseCase;

  setUp(() {
    repository = FakeAuthRepository();
    uploadUseCase = UploadAvatarUseCase(repository);
    deleteUseCase = DeleteAvatarUseCase(repository);
  });

  test('UploadAvatarUseCase returns avatar url when succeeds', () async {
    final result = await uploadUseCase(UploadAvatarParams(avatar: File('test_path.jpg')));
    expect(result.isRight(), isTrue);
    result.match(
      (_) => fail('Should succeed'),
      (url) => expect(url, 'https://res.cloudinary.com/avatar.webp'),
    );
  });

  test('UploadAvatarUseCase returns failure when fails', () async {
    repository.shouldFail = true;
    final result = await uploadUseCase(UploadAvatarParams(avatar: File('test_path.jpg')));
    expect(result.isLeft(), isTrue);
  });

  test('DeleteAvatarUseCase returns void when succeeds', () async {
    final result = await deleteUseCase(const NoParams());
    expect(result.isRight(), isTrue);
  });

  test('DeleteAvatarUseCase returns failure when fails', () async {
    repository.shouldFail = true;
    final result = await deleteUseCase(const NoParams());
    expect(result.isLeft(), isTrue);
  });
}
