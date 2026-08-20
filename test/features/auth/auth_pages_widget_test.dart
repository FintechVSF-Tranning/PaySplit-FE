import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/widgets/app_button.dart';
import 'package:paysplit/core/widgets/floating_input_card.dart';
import 'package:paysplit/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:paysplit/features/auth/presentation/pages/reset_password_page.dart';
import 'package:paysplit/features/auth/presentation/pages/verify_otp_page.dart';
import 'package:pinput/pinput.dart';

void main() {
  group('Auth Pages Widget Tests', () {
    testWidgets('ForgotPasswordPage renders properly with input and submit button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ForgotPasswordPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.byType(FloatingInputCard), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Gửi mã khôi phục'), findsOneWidget);
    });

    testWidgets('VerifyOtpPage renders properly with email, Pinput, and submit button', (tester) async {
      const testEmail = 'user@example.com';
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VerifyOtpPage(email: testEmail),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Xác thực Email'), findsOneWidget);
      expect(find.text(testEmail), findsOneWidget);
      expect(find.byType(Pinput), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Xác nhận & Kích hoạt'), findsOneWidget);
    });

    testWidgets('ResetPasswordPage renders properly with OTP and Password inputs', (tester) async {
      const testEmail = 'user@example.com';
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ResetPasswordPage(email: testEmail),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
      expect(find.text(testEmail), findsOneWidget);
      expect(find.byType(FloatingInputCard), findsNWidgets(3)); // OTP, New Password, Confirm Password
      expect(find.widgetWithText(AppButton, 'Lưu mật khẩu mới & Đăng nhập'), findsOneWidget);
    });
  });
}
