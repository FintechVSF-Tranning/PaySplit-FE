import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  });

  Future<Either<Failure, void>> verifyEmail({
    required String email,
    required String otp,
  });

  Future<Either<Failure, void>> resendVerification({
    required String email,
  });

  Future<Either<Failure, void>> forgotPassword({
    required String email,
  });

  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? phoneNumber,
    String? bankCode,
    String? bankAccountNumber,
    String? bankAccountHolder,
  });

  Future<Either<Failure, String>> uploadAvatar({
    File? avatar,
    List<int>? bytes,
    String? filename,
  });

  Future<Either<Failure, void>> deleteAvatar();

  Future<Either<Failure, void>> logout();
}
