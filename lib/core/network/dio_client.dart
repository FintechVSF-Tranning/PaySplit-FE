import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/env_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'session_events.dart';
import 'session_refresher.dart';
import 'token_storage.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  SessionRefresher sessionRefresher(
    TokenStorage tokenStorage,
    SessionEvents sessionEvents,
  ) => SessionRefresher(tokenStorage, sessionEvents);

  @lazySingleton
  Dio dio(
    TokenStorage tokenStorage,
    SessionEvents sessionEvents,
    SessionRefresher sessionRefresher,
  ) {
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
        refresher: sessionRefresher,
      ),
    );

    if (!EnvConfig.isProduction) {
      dio.interceptors.add(PrettyDioLogger());
    }

    return dio;
  }
}
