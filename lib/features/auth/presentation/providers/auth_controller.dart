import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/resend_verification_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_email_usecase.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<UserEntity?> build() async {
    final results = await Future.wait([
      getIt<GetCurrentUserUseCase>().call(const NoParams()),
      Future.delayed(const Duration(milliseconds: 2500)),
    ]);
    final result = results.first as dynamic;
    return result.match((_) => null, (user) => user);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await getIt<LoginUseCase>().call(LoginParams(email: email, password: password));
      return result.match((failure) => throw failure, (user) => user);
    });
  }

  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final result = await getIt<RegisterUseCase>().call(
      RegisterParams(name: name, email: email, password: password, phoneNumber: phoneNumber),
    );
    return result.match((failure) => throw failure, (user) => user);
  }

  Future<void> verifyEmail({required String email, required String otp}) async {
    final result = await getIt<VerifyEmailUseCase>().call(
      VerifyEmailParams(email: email, otp: otp),
    );
    result.match((failure) => throw failure, (_) => null);
  }

  Future<void> resendVerification({required String email}) async {
    final result = await getIt<ResendVerificationUseCase>().call(
      ResendVerificationParams(email: email),
    );
    result.match((failure) => throw failure, (_) => null);
  }

  Future<void> forgotPassword({required String email}) async {
    final result = await getIt<ForgotPasswordUseCase>().call(
      ForgotPasswordParams(email: email),
    );
    result.match((failure) => throw failure, (_) => null);
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final result = await getIt<ResetPasswordUseCase>().call(
      ResetPasswordParams(email: email, otp: otp, newPassword: newPassword),
    );
    result.match((failure) => throw failure, (_) => null);
  }

  void devSignIn() {
    if (!kDebugMode) return;
    state = const AsyncData(
      UserEntity(id: 'dev-user', name: 'Dev User', email: 'dev@paysplit.app'),
    );
  }

  Future<void> logout() async {
    await getIt<LogoutUseCase>().call(const NoParams());
    state = const AsyncData(null);
  }
}
