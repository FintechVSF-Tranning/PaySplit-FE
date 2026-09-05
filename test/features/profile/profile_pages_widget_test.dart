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
    testWidgets(
      'ChangePasswordPage: phím Next đi đúng chuỗi 3 ô, Done gửi form',
      (tester) async {
        // Không có textInputAction + onFieldSubmitted thì phím hành động của
        // bàn phím là ngõ cụt: người dùng phải chạm tay vào từng ô một.
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: ChangePasswordPage())),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        expect(fields, findsNWidgets(3));

        bool hasFocusAt(int index) =>
            tester.widget<TextField>(fields.at(index)).focusNode?.hasFocus ??
            false;

        // Mật khẩu hiện tại -> mật khẩu mới
        await tester.tap(fields.at(0));
        await tester.pumpAndSettle();
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();
        expect(hasFocusAt(1), isTrue);

        // Mật khẩu mới -> xác nhận
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();
        expect(hasFocusAt(2), isTrue);
        expect(hasFocusAt(1), isFalse);

        // Ô cuối: Done gọi thẳng _onSubmit. Mật khẩu còn trống nên form dừng ở
        // bước kiểm tra và báo lỗi — chính cái báo lỗi đó chứng minh Done đã
        // chạy submit chứ không phải rơi vào hư không.
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Vui lòng đáp ứng đầy đủ các yêu cầu bảo mật mật khẩu',
          ),
          findsOneWidget,
        );
      },
    );
    testWidgets(
      'BankSettingsPage: rời ô tên chủ tài khoản thì chuẩn hóa nốt từ cuối',
      (tester) async {
        // BankHolderInputFormatter cố ý đứng yên khi bộ gõ còn preedit mở, mà
        // IBus/Unikey giữ preedit tới tận lúc rời ô: bấm ra ngoài không sinh
        // thêm lượt cập nhật nào nên từ cuối nằm lại nguyên dạng vừa gõ.
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: BankSettingsPage())),
        );
        await tester.pumpAndSettle();

        final holderFinder = find.byType(TextFormField).last;
        final holder = tester.widget<TextFormField>(holderFinder);
        final controller = holder.controller!;

        await tester.tap(holderFinder);
        await tester.pumpAndSettle();

        // Trạng thái bộ gõ vừa chốt nhưng chưa qua formatter: chữ thường, còn
        // dấu, còn khoảng trắng thừa.
        controller.text = 'PHAM LE HOANG nam ';
        await tester.pumpAndSettle();
        expect(controller.text, 'PHAM LE HOANG nam ');

        // Bấm sang ô khác — đúng thao tác "ấn ra bên ngoài" của người dùng.
        await tester.tap(find.byType(TextFormField).first);
        await tester.pumpAndSettle();

        expect(controller.text, 'PHAM LE HOANG NAM');
      },
    );
  });
}
