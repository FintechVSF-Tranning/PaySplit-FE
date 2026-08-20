import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paysplit/core/widgets/app_button.dart';
import 'package:paysplit/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders the login form', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: LoginPage())));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.widgetWithText(AppButton, 'Đăng nhập'), findsOneWidget);
  });
}
