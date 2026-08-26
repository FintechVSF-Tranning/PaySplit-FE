import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/settlement/data/datasources/settlement_remote_data_source.dart';

void main() {
  group('SettlementRemoteDataSource', () {
    late Dio dio;
    late List<RequestOptions> requests;

    setUp(() {
      requests = [];
      dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
    });

    test(
      'sends selected debt IDs and an idempotency key when creating QR',
      () async {
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'success': true,
                    'data': {
                      'payment': {'id': 'payment-1'},
                    },
                  },
                ),
              );
            },
          ),
        );
        final source = SettlementRemoteDataSourceImpl(dio);

        final payment = await source.generatePaymentQr(
          groupId: 'group-1',
          creditorId: 'creditor-1',
          debtIds: const ['debt-1', 'debt-2'],
          idempotencyKey: 'key-qr-1',
        );

        expect(payment['id'], 'payment-1');
        expect(requests.single.path, '/groups/group-1/payments/qr');
        expect(requests.single.data, {
          'creditor_member_id': 'creditor-1',
          'debt_ids': ['debt-1', 'debt-2'],
        });
        expect(requests.single.headers['Idempotency-Key'], isNotEmpty);
      },
    );

    test('uploads the selected proof as multipart with the note', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'data': {}},
              ),
            );
          },
        ),
      );
      final source = SettlementRemoteDataSourceImpl(dio);

      await source.submitProof(
        groupId: 'group-1',
        paymentId: 'payment-1',
        imageName: 'receipt.png',
        imageBytes: Uint8List.fromList(const [1, 2, 3]),
        note: 'Đã chuyển khoản',
        idempotencyKey: 'key-proof-1',
      );

      final request = requests.single;
      expect(request.path, '/groups/group-1/payments/payment-1/proof');
      expect(request.headers['Idempotency-Key'], isNotEmpty);
      final form = request.data as FormData;
      expect(
        form.fields.any(
          (field) => field.key == 'note' && field.value == 'Đã chuyển khoản',
        ),
        true,
      );
      expect(form.files.single.key, 'image');
      expect(form.files.single.value.filename, 'receipt.png');
      expect(form.files.single.value.contentType.toString(), 'image/png');
    });

    test('follows cursors until every group page is loaded', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            final cursor = options.queryParameters['cursor'];
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'groups': [
                      {
                        'group': {'id': cursor == null ? 'group-1' : 'group-2'},
                      },
                    ],
                    'next_cursor': cursor == null ? 'next-page' : null,
                  },
                },
              ),
            );
          },
        ),
      );
      final source = SettlementRemoteDataSourceImpl(dio);

      final groups = await source.listGroups();

      expect(groups, hasLength(2));
      expect(requests, hasLength(2));
      expect(requests.last.queryParameters['cursor'], 'next-page');
    });

    test(
      'propagates an unauthorized response without exposing response data',
      () async {
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: 401,
                    data: const {
                      'success': false,
                      'error': {'code': 'UNAUTHORIZED'},
                    },
                  ),
                ),
              );
            },
          ),
        );
        final source = SettlementRemoteDataSourceImpl(dio);

        await expectLater(
          source.listGroups(),
          throwsA(
            isA<DioException>().having(
              (error) => error.response?.statusCode,
              'statusCode',
              401,
            ),
          ),
        );
      },
    );

    test('dừng phân trang khi server trả về cursor không tiến', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'groups': [
                      {
                        'group': {'id': 'g1'},
                        'caller_membership_id': 'm1',
                      },
                    ],
                    // luôn trả về cùng một cursor: vòng lặp cũ sẽ chạy vô hạn
                    'next_cursor': 'same-cursor',
                  },
                },
              ),
            );
          },
        ),
      );
      final source = SettlementRemoteDataSourceImpl(dio);

      final groups = await source.listGroups();

      expect(requests, hasLength(2), reason: 'dừng ngay khi cursor lặp lại');
      expect(groups, hasLength(2));
    });

    test('dừng phân trang khi chạm trần số trang', () async {
      var page = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'groups': const [],
                    'next_cursor': 'cursor-${page++}',
                  },
                },
              ),
            );
          },
        ),
      );
      final source = SettlementRemoteDataSourceImpl(dio, maxPages: 3);

      await source.listGroups();

      expect(requests, hasLength(3));
    });
  });
}
