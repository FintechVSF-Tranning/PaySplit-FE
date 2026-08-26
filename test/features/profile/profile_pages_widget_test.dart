import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/profile/presentation/pages/bank_settings_page.dart';
import 'package:paysplit/features/profile/presentation/pages/change_password_page.dart';
import 'package:paysplit/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:paysplit/features/profile/presentation/pages/profile_page.dart';

void main() {
  group('Profile Feature Widget Tests', () {
    testWidgets(
      'ProfilePage renders user profile, menu items, and logout button',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: ProfilePage())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
        expect(find.text('Người dùng'), findsOneWidget);
        expect(find.text('TÀI KHOẢN NHẬN TIỀN'), findsOneWidget);
        expect(find.text('Chưa liên kết tài khoản ngân hàng'), findsOneWidget);
        expect(find.text('TÀI KHOẢN & BẢO MẬT'), findsOneWidget);
        expect(find.text('Chỉnh sửa thông tin cá nhân'), findsOneWidget);
        expect(find.text('Đổi mật khẩu'), findsOneWidget);
        expect(find.text('Đăng xuất'), findsOneWidget);
        expect(find.text('PaySplit v1.0.0'), findsOneWidget);
      },
    );

    testWidgets(
      'BankSettingsPage renders live card preview and bank setup form',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: BankSettingsPage())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tài khoản VietQR'), findsOneWidget);
        expect(find.text('VIETQR NAPAS 247'), findsOneWidget);
        expect(find.text('THÔNG TIN TÀI KHOẢN NHẬN TIỀN'), findsOneWidget);
        expect(find.text('Ngân hàng thụ hưởng'), findsOneWidget);
        expect(find.text('Số tài khoản'), findsOneWidget);
        expect(
          find.text('Tên chủ tài khoản (In hoa không dấu)'),
          findsOneWidget,
        );
        expect(find.text('Lưu tài khoản VietQR'), findsOneWidget);
      },
    );

    testWidgets('EditProfilePage renders personal information form', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: EditProfilePage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chỉnh sửa thông tin'), findsOneWidget);
      expect(find.text('THÔNG TIN CÁ NHÂN'), findsOneWidget);
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Số điện thoại'), findsOneWidget);
      expect(find.text('Email (Không thể thay đổi)'), findsOneWidget);
      expect(find.text('Lưu thay đổi'), findsOneWidget);
    });

    testWidgets(
      'ChangePasswordPage renders password form and security checklist',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: ChangePasswordPage())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Đổi mật khẩu'), findsOneWidget);
        expect(find.text('Mật khẩu hiện tại'), findsOneWidget);
        expect(find.text('Mật khẩu mới'), findsOneWidget);
        expect(find.text('Tối thiểu 8 ký tự'), findsOneWidget);
        expect(find.text('Có ít nhất 1 chữ cái viết hoa'), findsOneWidget);
        expect(find.text('Có ít nhất 1 chữ số'), findsOneWidget);
        expect(find.text('Xác nhận mật khẩu mới'), findsOneWidget);
        expect(find.text('Cập nhật mật khẩu'), findsOneWidget);
      },
    );
  });
}
