import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/bank_entity.dart';
import '../../domain/repositories/bank_repository.dart';
import '../datasources/bank_remote_data_source.dart';

@LazySingleton(as: BankRepository)
class BankRepositoryImpl implements BankRepository {
  const BankRepositoryImpl(this._remoteDataSource);

  final BankRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<BankEntity>>> getSupportedBanks() async {
    try {
      final banks = await _remoteDataSource.getSupportedBanks();
      return Right(
        banks.map((bank) => bank.toEntity()).toList(growable: false),
      );
    } on DioException catch (error) {
      return Left(mapDioError(error));
    } catch (_) {
      return const Left(invalidResponseFailure);
    }
  }
}
