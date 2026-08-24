import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/bill_repository.dart';
import '../datasources/bill_remote_datasource.dart';

@LazySingleton(as: BillRepository)
class BillRepositoryImpl implements BillRepository {
  BillRepositoryImpl(this._remoteDataSource);

  final BillRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<BillEntity>>> getBills() async {
    try {
      final response = await _remoteDataSource.getBills();
      final models = response.data ?? const [];
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
  }
}
