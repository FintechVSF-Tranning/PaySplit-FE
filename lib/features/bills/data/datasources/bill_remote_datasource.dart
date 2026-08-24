import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../models/bill_model.dart';

part 'bill_remote_datasource.g.dart';

@RestApi()
@injectable
abstract class BillRemoteDataSource {
  @factoryMethod
  factory BillRemoteDataSource(Dio dio) = _BillRemoteDataSource;

  @GET(ApiEndpoints.bills)
  Future<ApiResponse<List<BillModel>>> getBills();
}
