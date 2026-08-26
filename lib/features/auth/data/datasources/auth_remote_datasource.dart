import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../models/auth_response_model.dart';

part 'auth_remote_datasource.g.dart';

@RestApi()
@injectable
abstract class AuthRemoteDataSource {
  @factoryMethod
  factory AuthRemoteDataSource(Dio dio) = _AuthRemoteDataSource;

  @POST(ApiEndpoints.login)
  Future<ApiResponse<AuthResponseModel>> login(
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiEndpoints.register)
  Future<ApiResponse<dynamic>> register(@Body() Map<String, dynamic> body);

  @POST(ApiEndpoints.verifyEmail)
  Future<ApiResponse<dynamic>> verifyEmail(@Body() Map<String, dynamic> body);

  @POST(ApiEndpoints.resendVerification)
  Future<ApiResponse<dynamic>> resendVerification(
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiEndpoints.forgotPassword)
  Future<ApiResponse<dynamic>> forgotPassword(
    @Body() Map<String, dynamic> body,
  );

  // 204 No Content: envelope không áp dụng, không có body.
  @POST(ApiEndpoints.resetPassword)
  Future<void> resetPassword(@Body() Map<String, dynamic> body);

  @GET(ApiEndpoints.me)
  Future<ApiResponse<dynamic>> getCurrentUser();

  @PATCH(ApiEndpoints.me)
  Future<ApiResponse<dynamic>> patchProfile(@Body() Map<String, dynamic> body);

  // 204 No Content: envelope không áp dụng, không có body.
  @PUT(ApiEndpoints.changePassword)
  Future<void> changePassword(@Body() Map<String, dynamic> body);

  @PUT(ApiEndpoints.avatar)
  Future<ApiResponse<dynamic>> uploadAvatar(@Body() FormData formData);

  // 204 No Content: envelope không áp dụng, không có body.
  @DELETE(ApiEndpoints.avatar)
  Future<void> deleteAvatar();
}
