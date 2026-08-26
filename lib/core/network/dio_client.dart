import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/env_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'session_events.dart';
import 'token_storage.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  Dio dio(TokenStorage tokenStorage, SessionEvents sessionEvents) {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 90),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage,
        EnvConfig.apiBaseUrl,
        sessionEvents: sessionEvents,
      ),
    );

    if (!EnvConfig.isProduction) {
      dio.interceptors.add(PrettyDioLogger());
    }

    return dio;
  }
}
