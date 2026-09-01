import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paysplit/core/error/failures.dart';
import 'package:paysplit/features/profile/data/datasources/bank_remote_data_source.dart';
import 'package:paysplit/features/profile/data/models/bank_model.dart';
import 'package:paysplit/features/profile/data/repositories/bank_repository_impl.dart';
import 'package:paysplit/features/profile/domain/entities/bank_entity.dart';

class MockBankRemoteDataSource extends Mock implements BankRemoteDataSource {}

void main() {
  group('BankRepositoryImpl', () {
    late MockBankRemoteDataSource mockRemoteDataSource;
    late BankRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = MockBankRemoteDataSource();
      repository = BankRepositoryImpl(mockRemoteDataSource);
    });

    const testModels = [
      BankModel(
        name: 'Ngân hàng TMCP Công thương Việt Nam',
        code: 'ICB',
        bin: '970415',
        shortName: 'VietinBank',
        logoUrl: 'https://cdn.vietqr.io/img/ICB.png',
      ),
      BankModel(
        name: 'Ngân hàng TMCP Ngoại Thương Việt Nam',
        code: 'VCB',
        bin: '970436',
        shortName: 'Vietcombank',
        logoUrl: 'https://cdn.vietqr.io/img/VCB.png',
      ),
    ];

    test(
      'trả về Right(List<BankEntity>) khi remote datasource thành công',
      () async {
        when(
          () => mockRemoteDataSource.getSupportedBanks(),
        ).thenAnswer((_) async => testModels);

        final result = await repository.getSupportedBanks();

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Should not be left: $failure'), (banks) {
          expect(banks.length, 2);
          expect(
            banks[0],
            const BankEntity(
              name: 'Ngân hàng TMCP Công thương Việt Nam',
              code: 'ICB',
              bin: '970415',
              shortName: 'VietinBank',
              logoUrl: 'https://cdn.vietqr.io/img/ICB.png',
            ),
          );
          expect(
            banks[1],
            const BankEntity(
              name: 'Ngân hàng TMCP Ngoại Thương Việt Nam',
              code: 'VCB',
              bin: '970436',
              shortName: 'Vietcombank',
              logoUrl: 'https://cdn.vietqr.io/img/VCB.png',
            ),
          );
        });
      },
    );

    test('map DioException thành Left(Failure)', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/banks'),
        type: DioExceptionType.connectionTimeout,
      );

      when(
        () => mockRemoteDataSource.getSupportedBanks(),
      ).thenThrow(dioException);

      final result = await repository.getSupportedBanks();

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<NetworkFailure>());
      }, (_) => fail('Should not be right'));
    });

    test(
      'map response sai cấu trúc / FormatException thành Left(invalidResponseFailure)',
      () async {
        when(
          () => mockRemoteDataSource.getSupportedBanks(),
        ).thenThrow(const FormatException('Invalid format'));

        final result = await repository.getSupportedBanks();

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, invalidResponseFailure);
        }, (_) => fail('Should not be right'));
      },
    );
  });
}
