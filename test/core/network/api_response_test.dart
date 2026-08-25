import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/network/api_response.dart';

void main() {
  group('ApiResponse.fromJson', () {
    test('parses a standard envelope with an object payload', () {
      final json = {
        'success': true,
        'data': {'id': '1', 'name': 'Lam'},
        'message': 'Thành công',
      };

      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        json,
        (j) => j as Map<String, dynamic>,
      );

      expect(response.success, isTrue);
      expect(response.data, {'id': '1', 'name': 'Lam'});
      expect(response.message, 'Thành công');
    });

    test('parses a generic list payload', () {
      final json = {
        'success': true,
        'data': [
          {'id': '1'},
          {'id': '2'},
        ],
        'message': 'Thành công',
      };

      final response = ApiResponse<List<String>>.fromJson(
        json,
        (j) => (j as List)
            .map((e) => (e as Map<String, dynamic>)['id'] as String)
            .toList(),
      );

      expect(response.data, ['1', '2']);
    });

    test('data is null when the envelope carries no payload', () {
      final json = {'success': true, 'data': null, 'message': 'Đã gửi email.'};

      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        json,
        (j) => j as Map<String, dynamic>,
      );

      expect(response.success, isTrue);
      expect(response.data, isNull);
      expect(response.message, 'Đã gửi email.');
    });

    test(
      'falls back to treating the whole body as data for a pre-migration BE (no "success" key)',
      () {
        final json = {'id': '1', 'name': 'Lam'};

        final response = ApiResponse<Map<String, dynamic>>.fromJson(
          json,
          (j) => j as Map<String, dynamic>,
        );

        expect(response.success, isTrue);
        expect(response.data, {'id': '1', 'name': 'Lam'});
        expect(response.message, isNull);
      },
    );
  });

  group('ApiResponse.requireData', () {
    test('returns data when present', () {
      const response = ApiResponse<String>(success: true, data: 'hello');
      expect(response.requireData, 'hello');
    });

    test('throws when data is null', () {
      const response = ApiResponse<String>(success: true);
      expect(() => response.requireData, throwsStateError);
    });
  });
}
