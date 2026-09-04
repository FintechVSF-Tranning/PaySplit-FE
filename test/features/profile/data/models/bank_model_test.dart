import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/profile/data/models/bank_model.dart';
import 'package:paysplit/features/profile/domain/entities/bank_entity.dart';

void main() {
  group('BankModel', () {
    const validJson = {
      'id': 17,
      'name': 'Ngân hàng TMCP Công thương Việt Nam',
      'code': 'ICB',
      'bin': '970415',
      'short_name': 'VietinBank',
      'logo': 'https://cdn.vietqr.io/img/ICB.png',
      'supported': true,
    };

    test('parse đúng name, code, bin, short_name và logo từ json', () {
      final model = BankModel.fromJson(validJson);

      expect(model.name, 'Ngân hàng TMCP Công thương Việt Nam');
      expect(model.code, 'ICB');
      expect(model.bin, '970415');
      expect(model.shortName, 'VietinBank');
      expect(model.logoUrl, 'https://api.vietqr.io/img/ICB.png');
    });

    test('fallback logoUrl thành chuỗi rỗng khi logo là null hoặc thiếu', () {
      final jsonWithoutLogo = {
        'id': 99,
        'name': 'Ngân hàng Mẫu',
        'code': 'SAMPLE',
        'bin': '970499',
        'short_name': 'SampleBank',
        'supported': true,
      };

      final modelWithoutLogo = BankModel.fromJson(jsonWithoutLogo);
      expect(modelWithoutLogo.logoUrl, '');

      final jsonWithNullLogo = {
        'id': 99,
        'name': 'Ngân hàng Mẫu',
        'code': 'SAMPLE',
        'bin': '970499',
        'short_name': 'SampleBank',
        'logo': null,
        'supported': true,
      };

      final modelWithNullLogo = BankModel.fromJson(jsonWithNullLogo);
      expect(modelWithNullLogo.logoUrl, '');
    });

    test('toEntity chuyển đổi chính xác sang BankEntity', () {
      final model = BankModel.fromJson(validJson);
      final entity = model.toEntity();

      expect(
        entity,
        const BankEntity(
          name: 'Ngân hàng TMCP Công thương Việt Nam',
          code: 'ICB',
          bin: '970415',
          shortName: 'VietinBank',
          logoUrl: 'https://api.vietqr.io/img/ICB.png',
        ),
      );
    });
  });
}
