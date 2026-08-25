import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/bill_detail_entity.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/entities/captured_bill_photo.dart';
import '../../domain/repositories/bill_repository.dart';
import '../datasources/bill_remote_datasource.dart';

@LazySingleton(as: BillRepository)
class BillRepositoryImpl implements BillRepository {
  BillRepositoryImpl(this._remoteDataSource);

  final BillRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<BillEntity>>> getBills({
    String groupId = '',
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final models = await _remoteDataSource.getBills(
        groupId: groupId,
        limit: limit,
        cursor: cursor,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillDetailEntity>> createBillWithPhotos({
    required String groupId,
    String? merchantName,
    required List<CapturedBillPhoto> photos,
  }) async {
    try {
      final bill = await _remoteDataSource.createBillWithPhotos(
        groupId: groupId,
        merchantName: merchantName,
        photos: photos,
      );
      return Right(bill);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillDetailEntity>> createManualBill({
    required String groupId,
    required String merchantName,
    required int total,
    required List<BillItemEntity> items,
  }) async {
    try {
      final bill = await _remoteDataSource.createManualBill(
        groupId: groupId,
        merchantName: merchantName,
        total: total,
        items: items,
      );
      return Right(bill);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillDetailEntity>> getBillDetail({
    required String billId,
    required String groupId,
  }) async {
    try {
      final bill = await _remoteDataSource.getBillDetail(
        billId: billId,
        groupId: groupId,
      );
      return Right(bill);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillDetailEntity>> updateDraftBill({
    required String billId,
    required String groupId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final bill = await _remoteDataSource.updateDraftBill(
        billId: billId,
        groupId: groupId,
        payload: payload,
      );
      return Right(bill);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BillDetailEntity>> reviewBill({
    required String billId,
    required String groupId,
    required int version,
  }) async {
    try {
      final bill = await _remoteDataSource.reviewBill(
        billId: billId,
        groupId: groupId,
        version: version,
      );
      return Right(bill);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> finalizeBill({
    required String billId,
    required String groupId,
    required int version,
  }) async {
    try {
      await _remoteDataSource.finalizeBill(
        billId: billId,
        groupId: groupId,
        version: version,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BillShareBreakdownEntity>>> calculateBreakdown({
    String? billId,
    required String groupId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final breakdown = await _remoteDataSource.calculateBreakdown(
        billId: billId,
        groupId: groupId,
        payload: payload,
      );
      return Right(breakdown);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BillMemberEntity>>> getGroupMembers({
    required String groupId,
  }) async {
    try {
      final members = await _remoteDataSource.getGroupMembers(groupId: groupId);
      return Right(members);
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
