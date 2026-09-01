import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/auth/domain/entities/user_entity.dart';
import 'package:paysplit/features/auth/presentation/providers/auth_controller.dart';
import 'package:paysplit/features/profile/domain/entities/bank_entity.dart';
import 'package:paysplit/features/profile/presentation/pages/bank_settings_page.dart';
import 'package:paysplit/features/profile/presentation/providers/supported_banks_provider.dart';

const _mockBanks = [
  BankEntity(
    name: 'Ngân hàng TMCP Công thương Việt Nam',
    code: 'ICB',
    bin: '970415',
    shortName: 'VietinBank',
    logoUrl: 'https://cdn.vietqr.io/img/ICB.png',
  ),
  BankEntity(
    name: 'Ngân hàng TMCP Ngoại Thương Việt Nam',
    code: 'VCB',
    bin: '970436',
    shortName: 'Vietcombank',
    logoUrl: 'https://cdn.vietqr.io/img/VCB.png',
  ),
  BankEntity(
    name: 'Ngân hàng TMCP Quân đội',
    code: 'MB',
    bin: '970422',
    shortName: 'MBBank',
    logoUrl: '',
  ),
];

class _TestAuthController extends AuthController {
  _TestAuthController({this.initialUser});

  final UserEntity? initialUser;
  bool updateProfileCalled = false;
  String? updatedBankCode;
  String? updatedBankAccountNumber;
  String? updatedBankAccountHolder;

  @override
  FutureOr<UserEntity?> build() {
    return initialUser ??
        const UserEntity(
          id: 'user-1',
          name: 'Nguyen Van A',
          email: 'test@paysplit.app',
        );
  }

  @override
  Future<UserEntity> updateProfile({
    String? name,
    String? phoneNumber,
    String? bankCode,
    String? bankAccountNumber,
    String? bankAccountHolder,
  }) async {
    updateProfileCalled = true;
    updatedBankCode = bankCode;
    updatedBankAccountNumber = bankAccountNumber;
    updatedBankAccountHolder = bankAccountHolder;
    return UserEntity(
      id: 'user-1',
      name: name ?? 'Nguyen Van A',
      email: 'test@paysplit.app',
      phoneNumber: phoneNumber,
      bankCode: bankCode,
      bankAccountNumber: bankAccountNumber,
      bankAccountHolder: bankAccountHolder,
    );
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget buildTestWidget({required List<Override> overrides}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: BankSettingsPage()),
    );
  }

  group('BankSettingsPage Widget Tests', () {
    testWidgets('hiển thị loading state khi đang tải danh sách ngân hàng', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completer = Completer<List<BankEntity>>();

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            authControllerProvider.overrideWith(_TestAuthController.new),
            supportedBanksProvider.overrideWith((ref) => completer.future),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Đang tải danh sách ngân hàng...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hiển thị error state và cho phép retry khi chạm', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var callCount = 0;

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            authControllerProvider.overrideWith(_TestAuthController.new),
            supportedBanksProvider.overrideWith((ref) {
              callCount++;
              if (callCount == 1) {
                return Future.error(Exception('Network error'));
              }
              return Future.value(_mockBanks);
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Không tải được danh sách. Chạm để thử lại'),
        findsOneWidget,
      );

      // Chạm để retry
      await tester.tap(find.text('Không tải được danh sách. Chạm để thử lại'));
      await tester.pumpAndSettle();

      expect(callCount, 2);
      expect(find.text('Chọn ngân hàng thụ hưởng'), findsOneWidget);
    });

    testWidgets('hiển thị empty state khi không có ngân hàng được hỗ trợ', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            authControllerProvider.overrideWith(_TestAuthController.new),
            supportedBanksProvider.overrideWith(
              (ref) => Future.value(<BankEntity>[]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có ngân hàng được hỗ trợ'), findsOneWidget);
    });

    testWidgets(
      'mở modal danh sách ngân hàng, tìm kiếm và hiển thị logo hoặc fallback',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              authControllerProvider.overrideWith(_TestAuthController.new),
              supportedBanksProvider.overrideWith(
                (ref) => Future.value(_mockBanks),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Mở modal
        await tester.tap(find.text('Chọn ngay'));
        await tester.pumpAndSettle();

        expect(find.text('Chọn ngân hàng thụ hưởng'), findsNWidgets(2));
        expect(find.text('VietinBank'), findsOneWidget);
        expect(find.text('Vietcombank'), findsOneWidget);
        expect(find.text('MBBank'), findsOneWidget);

        // Fallback text 3 ký tự đầu mã code cho ngân hàng không có logo (MB)
        expect(find.text('MB'), findsWidgets);

        // Tìm kiếm theo shortName
        await tester.enterText(find.byType(TextField).last, 'vietin');
        await tester.pumpAndSettle();

        expect(find.text('VietinBank'), findsOneWidget);
        expect(find.text('Vietcombank'), findsNothing);
        expect(find.text('MBBank'), findsNothing);

        // Tìm kiếm theo name
        await tester.enterText(find.byType(TextField).last, 'Ngoại Thương');
        await tester.pumpAndSettle();

        expect(find.text('Vietcombank'), findsOneWidget);
        expect(find.text('VietinBank'), findsNothing);

        // Tìm kiếm theo code duy nhất (ICB)
        await tester.enterText(find.byType(TextField).last, 'ICB');
        await tester.pumpAndSettle();

        expect(find.text('VietinBank'), findsOneWidget);
        expect(find.text('Vietcombank'), findsNothing);
        expect(find.text('MBBank'), findsNothing);

        // Tìm kiếm theo tên MBBank
        await tester.enterText(find.byType(TextField).last, 'Quân đội');
        await tester.pumpAndSettle();

        expect(find.text('MBBank'), findsOneWidget);
        expect(find.text('VietinBank'), findsNothing);
        expect(find.text('Vietcombank'), findsNothing);

        // Chọn MBBank
        await tester.tap(find.text('MBBank'));
        await tester.pumpAndSettle();

        // Modal đã đóng, UI cập nhật MBBank
        expect(find.text('CHƯA CHỌN NGÂN HÀNG'), findsNothing);
        expect(find.text('MBBank'), findsWidgets);
        expect(find.text('Đổi ngân hàng'), findsOneWidget);
      },
    );

    testWidgets('hỗ trợ tài khoản cũ dùng CTG bằng cách ánh xạ sang ICB', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const userWithOldCtg = UserEntity(
        id: 'user-ctg',
        name: 'Nguyen Van A',
        email: 'ctg@paysplit.app',
        bankCode: 'CTG',
        bankAccountNumber: '9876543210',
        bankAccountHolder: 'NGUYEN VAN A',
      );

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            authControllerProvider.overrideWith(
              () => _TestAuthController(initialUser: userWithOldCtg),
            ),
            supportedBanksProvider.overrideWith(
              (ref) => Future.value(_mockBanks),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Ánh xạ CTG sang ICB (VietinBank)
      expect(find.text('VietinBank'), findsWidgets);
      expect(find.text('9876543210'), findsWidgets);
      expect(find.text('NGUYEN VAN A'), findsWidgets);
      expect(find.text('Đổi ngân hàng'), findsOneWidget);
    });

    testWidgets('chọn ngân hàng, nhập thông tin và lưu thành công', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late _TestAuthController authController;

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            authControllerProvider.overrideWith(() {
              authController = _TestAuthController();
              return authController;
            }),
            supportedBanksProvider.overrideWith(
              (ref) => Future.value(_mockBanks),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Chọn ngân hàng Vietcombank
      await tester.tap(find.text('Chọn ngay'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vietcombank'));
      await tester.pumpAndSettle();

      // Nhập số tài khoản (form field 0)
      await tester.enterText(find.byType(TextFormField).at(0), '0011001234567');
      // Nhập tên chủ tài khoản (form field 1)
      await tester.enterText(find.byType(TextFormField).at(1), 'TRAN VAN B');
      await tester.pumpAndSettle();

      // Nút Lưu có hiệu lực
      final saveButton = find.text('Lưu tài khoản VietQR');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(authController.updateProfileCalled, isTrue);
      expect(authController.updatedBankCode, 'VCB');
      expect(authController.updatedBankAccountNumber, '0011001234567');
      expect(authController.updatedBankAccountHolder, 'TRAN VAN B');
    });
  });
}
