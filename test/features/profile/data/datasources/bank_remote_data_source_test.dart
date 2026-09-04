import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/constants/api_endpoints.dart';
import 'package:paysplit/features/profile/data/datasources/bank_remote_data_source.dart';

void main() {
  group('BankRemoteDataSource', () {
    late List<RequestOptions> requests;

    Dio createMockDio({dynamic data, int statusCode = 200}) {
      final client = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: statusCode,
                data: data,
              ),
            );
          },
        ),
      );
      return client;
    }

    setUp(() {
      requests = [];
    });

    test(
      'gọi GET /banks với query supported=true và parse đúng danh sách ngân hàng',
      () async {
        final mockData = {
          'success': true,
          'data': {
            'banks': [
              {
                'id': 17,
                'name': 'Ngân hàng TMCP Công thương Việt Nam',
                'code': 'ICB',
                'bin': '970415',
                'short_name': 'VietinBank',
                'logo': 'https://cdn.vietqr.io/img/ICB.png',
                'supported': true,
              },
              {
                'id': 43,
                'name': 'Ngân hàng TMCP Ngoại Thương Việt Nam',
                'code': 'VCB',
                'bin': '970436',
                'short_name': 'Vietcombank',
                'logo': 'https://cdn.vietqr.io/img/VCB.png',
                'supported': true,
              },
            ],
          },
        };

        final dio = createMockDio(data: mockData);
        final dataSource = BankRemoteDataSource(dio);

        final banks = await dataSource.getSupportedBanks();

        expect(requests.length, 1);
        final request = requests.single;
        expect(request.method, 'GET');
        expect(request.path, ApiEndpoints.banks);
        expect(request.queryParameters, {'supported': true});

        expect(banks.length, 2);
        expect(banks[0].code, 'ICB');
        expect(banks[0].shortName, 'VietinBank');
        expect(banks[0].logoUrl, 'https://api.vietqr.io/img/ICB.png');
        expect(banks[1].code, 'VCB');
        expect(banks[1].shortName, 'Vietcombank');
        expect(banks[1].logoUrl, 'https://api.vietqr.io/img/VCB.png');
      },
    );

    test('ném FormatException khi response body là null', () async {
      final dio = createMockDio();
      final dataSource = BankRemoteDataSource(dio);

      expect(
        () => dataSource.getSupportedBanks(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
