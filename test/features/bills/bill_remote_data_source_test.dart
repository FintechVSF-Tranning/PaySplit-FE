import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/bills/data/datasources/bill_remote_datasource.dart';
import 'package:paysplit/features/bills/domain/entities/bill_detail_entity.dart';

void main() {
  group('BillRemoteDataSource', () {
    late Dio dio;
    late List<RequestOptions> requests;

    Dio dioReturning(Map<String, dynamic> data, {int statusCode = 200}) {
      final client = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: statusCode,
                data: {'success': true, 'data': data},
              ),
            );
          },
        ),
      );
      return client;
    }

    setUp(() => requests = []);

    test('gửi status lên GET /bills theo dạng lặp param', () async {
      dio = dioReturning({
        'bills': const [],
        'counts': {'draft': 2, 'total': 2},
      });

      final page = await BillRemoteDataSourceImpl(dio).getBills(
        groupId: 'group-1',
        statuses: const ['draft', 'reviewed'],
      );

      expect(requests.single.queryParameters['status'], ['draft', 'reviewed']);
      expect(requests.single.queryParameters['group_id'], 'group-1');
      expect(page.counts['draft'], 2);
      expect(page.totalCount, 2);
    });

    test('không lọc thì không gửi param status', () async {
      dio = dioReturning({'bills': const []});

      await BillRemoteDataSourceImpl(dio).getBills(groupId: 'group-1');

      expect(requests.single.queryParameters.containsKey('status'), isFalse);
    });

    test(
      'tạo hóa đơn thủ công gửi đủ thuế phí, split_method và các món đã gán người',
      () async {
        dio = dioReturning({
          'bill': {'id': 'bill-1', 'group_id': 'group-1', 'status': 'draft'},
        }, statusCode: 201);

        await BillRemoteDataSourceImpl(dio).createManualBill(
          groupId: 'group-1',
          merchantName: 'Bách Hóa Xanh',
          total: 110000,
          subtotal: 100000,
          serviceCharge: 5000,
          vat: 5000,
          splitMethod: 'exact',
          items: const [
            BillItemEntity(
              id: 'item-1',
              name: 'Bì xanh',
              lineTotal: 100000,
              finalPrice: 100000,
              assignments: [
                BillItemAssignmentEntity(memberId: 'member-1'),
                BillItemAssignmentEntity(memberId: 'member-2', weight: 2),
              ],
            ),
          ],
        );

        final body = requests.single.data as Map<String, dynamic>;
        expect(body['subtotal'], 100000);
        expect(body['service_charge'], 5000);
        expect(body['vat'], 5000);
        expect(body['split_method'], 'exact');

        final items = body['items'] as List;
        final assignments = (items.single as Map<String, dynamic>)['assignments'] as List;
        expect(assignments.length, 2);
        expect((assignments.first as Map<String, dynamic>)['member_id'], 'member-1');
        expect((assignments.last as Map<String, dynamic>)['weight'], '2.0');
      },
    );

    test('xóa hóa đơn nháp gửi DELETE kèm group_id và khóa idempotency', () async {
      dio = dioReturning(const {}, statusCode: 204);

      await BillRemoteDataSourceImpl(
        dio,
      ).deleteDraftBill(billId: 'bill-1', groupId: 'group-1');

      final request = requests.single;
      expect(request.method, 'DELETE');
      expect(request.path, '/bills/bill-1');
      expect(request.queryParameters['group_id'], 'group-1');
      expect(request.headers['Idempotency-Key'], isNotEmpty);
    });

    test('hóa đơn đã chốt: shares được dùng làm breakdown', () async {
      dio = dioReturning({
        'bill': {
          'id': 'bill-1',
          'group_id': 'group-1',
          'status': 'finalized',
          'total': 100000,
          'shares': [
            {
              'member_id': 'member-1',
              'item_subtotal': 60000,
              'service_charge_share': 0,
              'vat_share': 0,
              'discount_share': 0,
              'final_amount': 60000,
            },
          ],
        },
      });

      final bill = await BillRemoteDataSourceImpl(
        dio,
      ).getBillDetail(billId: 'bill-1', groupId: 'group-1');

      expect(bill.breakdown.single.memberId, 'member-1');
      expect(bill.breakdown.single.finalAmount, 60000);
    });
  });
}
