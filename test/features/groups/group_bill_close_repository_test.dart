import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/groups/data/datasources/group_bill_close_remote_data_source.dart';
import 'package:paysplit/features/groups/data/repositories/group_bill_close_repository_impl.dart';
import 'package:paysplit/features/groups/domain/entities/bulk_finalize_entity.dart';

void main() {
  late Dio dio;
  late List<RequestOptions> requests;

  setUp(() {
    requests = [];
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
  });

  test('AC 5 bắt đầu batch với khóa idempotency và đọc summary', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 202,
              data: {
                'success': true,
                'data': {
                  'batch': {
                    'id': 'batch-1',
                    'status': 'queued',
                    'target_count': 3,
                    'finalized_count': 0,
                    'failed_count': 0,
                  },
                },
              },
            ),
          );
        },
      ),
    );
    final repository = GroupBillCloseRepositoryImpl(
      GroupBillCloseRemoteDataSource(dio),
    );

    final result = await repository.start(
      'group-1',
      idempotencyKey: 'idem-key-1',
    );

    final batch = result.getOrElse((_) => throw StateError('expected success'));
    expect(batch.id, 'batch-1');
    expect(batch.status, BulkFinalizeStatus.queued);
    expect(requests.single.path, '/groups/group-1/bills/finalize-all');
    expect(requests.single.headers['Idempotency-Key'], 'idem-key-1');
  });

  test('AC 6 map tiến trình và lỗi từng bill, có cursor trang sau', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              data: {
                'success': true,
                'data': {
                  'batch': {
                    'id': 'batch-1',
                    'status': 'completed',
                    'target_count': 2,
                    'finalized_count': 1,
                    'failed_count': 1,
                  },
                  'items': [
                    {
                      'bill_id': 'bill-1',
                      'bill_display_name': 'Bữa tối',
                      'status': 'finalized',
                    },
                    {
                      'bill_id': 'bill-2',
                      'bill_display_name': 'Siêu thị',
                      'status': 'failed',
                      'error_code': 'VERSION_CONFLICT',
                    },
                  ],
                  'next_cursor': 'next-page',
                },
              },
            ),
          );
        },
      ),
    );
    final repository = GroupBillCloseRepositoryImpl(
      GroupBillCloseRemoteDataSource(dio),
    );

    final result = await repository.getBatch(
      'group-1',
      'batch-1',
      cursor: 'cursor-1',
    );

    final batch = result.getOrElse((_) => throw StateError('expected success'));
    expect(batch.isComplete, isTrue);
    expect(batch.items, hasLength(2));
    expect(batch.items.last.errorCode, 'VERSION_CONFLICT');
    expect(batch.items.last.resultText, contains('vừa thay đổi'));
    expect(batch.nextCursor, 'next-page');
    expect(requests.single.queryParameters['cursor'], 'cursor-1');
  });

  test('response sai contract được đổi thành failure an toàn', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: {'success': true, 'data': const {}},
          ),
        ),
      ),
    );
    final repository = GroupBillCloseRepositoryImpl(
      GroupBillCloseRemoteDataSource(dio),
    );

    final result = await repository.start(
      'group-1',
      idempotencyKey: 'idem-key-2',
    );

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure.code, 'INVALID_RESPONSE'),
      (_) => fail('expected failure'),
    );
  });
}
