import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

part 'auth_controller.g.dart';

/// Holds the current session: `null` means signed out, [AsyncError] means
/// the last auth action failed, [AsyncLoading] drives spinners on the
/// login/register buttons. Usecases are resolved from [getIt] rather than
/// re-exposed as Riverpod providers — DI wires the data layer, Riverpod
/// wires the UI state, and this controller is the seam between the two.
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<UserEntity?> build() async {
    final result = await getIt<GetCurrentUserUseCase>().call(const NoParams());
    return result.match((_) => null, (user) => user);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await getIt<LoginUseCase>().call(LoginParams(email: email, password: password));
      return result.match((failure) => throw failure, (user) => user);
    });
  }

  Future<void> register({required String name, required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await getIt<RegisterUseCase>().call(
        RegisterParams(name: name, email: email, password: password),
      );
      return result.match((failure) => throw failure, (user) => user);
    });
  }

  /// Debug-only shortcut that fakes a session so the post-login screens can
  /// be opened without a reachable backend. No token is written to storage,
  /// so any real API call from those screens still fails with 401 — this is
  /// for eyeballing layouts, not for exercising the data layer.
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
