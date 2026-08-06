import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

part 'auth_remote_datasource.g.dart';

/// Retrofit generates the HTTP implementation of this interface at build
/// time (`auth_remote_datasource.g.dart`). Errors surface to callers as
/// [DioException] — the repository is responsible for catching those and
/// mapping them to [Failure]s via `mapDioError`.
@RestApi()
@injectable
abstract class AuthRemoteDataSource {
  @factoryMethod
  factory AuthRemoteDataSource(Dio dio) = _AuthRemoteDataSource;

  @POST(ApiEndpoints.login)
  Future<AuthResponseModel> login(@Body() Map<String, dynamic> body);

  @POST(ApiEndpoints.register)
  Future<AuthResponseModel> register(@Body() Map<String, dynamic> body);

  @GET(ApiEndpoints.me)
  Future<UserModel> getCurrentUser();
}
