import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/session/session_scope.dart';
import '../../../../core/network/session_events.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/delete_avatar_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/resend_verification_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';
import '../../domain/usecases/verify_email_usecase.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<UserEntity?> build() async {
    // Phiên bị thu hồi / refresh token hỏng: đưa app về trạng thái chưa đăng
    // nhập để router tự chuyển ra màn chào, thay vì để người dùng kẹt lại trong
    // màn hình cũ với mọi API trả 401.
    final subscription = getIt<SessionEvents>().onExpired.listen((_) {
      state = const AsyncData(null);
    });
    ref.onDispose(subscription.cancel);

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
      final user = result.match((failure) => throw failure, (user) => user);
      // Bắt đầu phiên mới ngay khi đăng nhập thành công, nếu không màn hình
      // đầu tiên sau đăng nhập sẽ hiện lại dữ liệu của tài khoản trước.
      beginNewSession(ref);
      return user;
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await getIt<ChangePasswordUseCase>().call(
      ChangePasswordParams(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
    result.match((failure) => throw failure, (_) => null);
  }

  Future<UserEntity> updateProfile({
    String? name,
    String? phoneNumber,
    String? bankCode,
    String? bankAccountNumber,
    String? bankAccountHolder,
  }) async {
    final result = await getIt<UpdateProfileUseCase>().call(
      UpdateProfileParams(
        name: name,
        phoneNumber: phoneNumber,
        bankCode: bankCode,
        bankAccountNumber: bankAccountNumber,
        bankAccountHolder: bankAccountHolder,
      ),
    );
    return result.match(
      (failure) => throw failure,
      (user) {
        state = AsyncData(user);
        return user;
      },
    );
  }

  Future<String> uploadAvatar({
    File? avatar,
    List<int>? bytes,
    String? filename,
  }) async {
    final result = await getIt<UploadAvatarUseCase>().call(
      UploadAvatarParams(
        avatar: avatar,
        bytes: bytes,
        filename: filename,
      ),
    );
    return result.match(
      (failure) => throw failure,
      (avatarUrl) {
        final currentUser = state.valueOrNull;
        if (currentUser != null) {
          state = AsyncData(currentUser.copyWith(avatarUrl: avatarUrl));
        }
        return avatarUrl;
      },
    );
  }

  Future<void> deleteAvatar() async {
    final result = await getIt<DeleteAvatarUseCase>().call(const NoParams());
    return result.match(
      (failure) => throw failure,
      (_) {
        final currentUser = state.valueOrNull;
        if (currentUser != null) {
          state = AsyncData(currentUser.copyWith(avatarUrl: null));
        }
      },
    );
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
