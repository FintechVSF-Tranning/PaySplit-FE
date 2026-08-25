import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../../../core/network/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._tokenStorage);

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final deviceId = await _tokenStorage.getOrCreateDeviceId();
      final response = await _remoteDataSource.login({
        'email': email,
        'password': password,
        'device_id': deviceId,
        'device_name': 'Mobile Device',
      });
      final auth = response.requireData;
      await _tokenStorage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
      return Right(auth.user.toEntity());
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (_) {
      return const Left(invalidResponseFailure);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final body = <String, dynamic>{'display_name': name, 'email': email, 'password': password};
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        body['phone_number'] = phoneNumber;
      }
      final response = await _remoteDataSource.register(body);
      final userJson = (response.data as Map<String, dynamic>?)?['user'] as Map<String, dynamic>?;
      if (userJson != null) {
        final userModel = UserModel.fromJson(userJson);
        return Right(userModel.toEntity());
      }
      return Right(UserEntity(id: 'temp', name: name, email: email, phoneNumber: phoneNumber));
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (_) {
      return const Left(invalidResponseFailure);
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmail({required String email, required String otp}) async {
    try {
      await _remoteDataSource.verifyEmail({'email': email, 'otp': otp});
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> resendVerification({required String email}) async {
    try {
      await _remoteDataSource.resendVerification({'email': email});
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    try {
      await _remoteDataSource.forgotPassword({'email': email});
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.resetPassword({
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      });
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final response = await _remoteDataSource.getCurrentUser();
      final data = response.data;
      final userJson =
          (data is Map<String, dynamic> ? data['user'] as Map<String, dynamic>? : null) ??
          data as Map<String, dynamic>;
      final model = UserModel.fromJson(userJson);
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (_) {
      return const Left(invalidResponseFailure);
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.changePassword({
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? phoneNumber,
    String? bankCode,
    String? bankAccountNumber,
    String? bankAccountHolder,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['display_name'] = name;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (bankCode != null) body['bank_code'] = bankCode;
      if (bankAccountNumber != null) {
        body['bank_account_number'] = bankAccountNumber;
      }
      if (bankAccountHolder != null) {
        body['bank_account_holder'] = bankAccountHolder;
      }

      final response = await _remoteDataSource.patchProfile(body);
      final data = response.data;
      final userJson =
          (data is Map<String, dynamic> ? data['user'] as Map<String, dynamic>? : null) ??
          data as Map<String, dynamic>;
      final model = UserModel.fromJson(userJson);
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (_) {
      return const Left(invalidResponseFailure);
    }
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(File avatar) async {
    try {
      final response = await _remoteDataSource.uploadAvatar(avatar);
      final data = response.data;
      final avatarUrl = (data is Map<String, dynamic>)
          ? data['avatar_url'] as String? ?? ''
          : data.toString();
      return Right(avatarUrl);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (_) {
      return const Left(invalidResponseFailure);
    }
  }

  @override
  Future<Either<Failure, void>> deleteAvatar() async {
    try {
      await _remoteDataSource.deleteAvatar();
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    await _tokenStorage.clear();
    return const Right(null);
  }
}
