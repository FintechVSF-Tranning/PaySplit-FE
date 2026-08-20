import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/auth_response_model.dart';

part 'auth_remote_datasource.g.dart';

@RestApi()
@injectable
abstract class AuthRemoteDataSource {
  @factoryMethod
  factory AuthRemoteDataSource(Dio dio) = _AuthRemoteDataSource;

  @POST(ApiEndpoints.login)
  Future<AuthResponseModel> login(@Body() Map<String, dynamic> body);

  @POST(ApiEndpoints.register)
  Future<dynamic> register(@Body() Map<String, dynamic> body);

  @POST(ApiEndpoints.verifyEmail)
  Future<dynamic> verifyEmail(@Body() Map<String, dynamic> body);

  @POST(ApiEndpoints.resendVerification)
  Future<dynamic> resendVerification(@Body() Map<String, dynamic> body);

  @POST(ApiEndpoints.forgotPassword)
  Future<dynamic> forgotPassword(@Body() Map<String, dynamic> body);

  @POST(ApiEndpoints.resetPassword)
  Future<void> resetPassword(@Body() Map<String, dynamic> body);

  @GET(ApiEndpoints.me)
  Future<dynamic> getCurrentUser();

  @PATCH(ApiEndpoints.me)
  Future<dynamic> patchProfile(@Body() Map<String, dynamic> body);

  @PUT(ApiEndpoints.changePassword)
  Future<void> changePassword(@Body() Map<String, dynamic> body);

  @PUT(ApiEndpoints.avatar)
  @MultiPart()
  Future<dynamic> uploadAvatar(@Part(name: 'avatar') File avatar);

  @DELETE(ApiEndpoints.avatar)
  Future<void> deleteAvatar();
}
