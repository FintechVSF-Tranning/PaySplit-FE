import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paysplit/core/usecase/usecase.dart';
import 'package:paysplit/features/profile/domain/entities/bank_entity.dart';
import 'package:paysplit/features/profile/domain/repositories/bank_repository.dart';
import 'package:paysplit/features/profile/domain/usecases/get_supported_banks_usecase.dart';

class MockBankRepository extends Mock implements BankRepository {}

void main() {
  group('GetSupportedBanksUseCase', () {
    late MockBankRepository mockRepository;
    late GetSupportedBanksUseCase useCase;

    setUp(() {
      mockRepository = MockBankRepository();
      useCase = GetSupportedBanksUseCase(mockRepository);
    });

    const testBanks = [
      BankEntity(
        name: 'Ngân hàng TMCP Công thương Việt Nam',
        code: 'ICB',
        bin: '970415',
        shortName: 'VietinBank',
        logoUrl: 'https://cdn.vietqr.io/img/ICB.png',
      ),
    ];

    test('gọi getSupportedBanks từ BankRepository và trả về kết quả', () async {
      when(
        () => mockRepository.getSupportedBanks(),
      ).thenAnswer((_) async => const Right(testBanks));

      final result = await useCase(const NoParams());

      expect(result, const Right(testBanks));
      verify(() => mockRepository.getSupportedBanks()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
