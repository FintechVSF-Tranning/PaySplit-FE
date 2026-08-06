import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paysplit/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders the login form', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: LoginPage())));
    await tester.pump();

    expect(find.text('PaySplit'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Đăng nhập'), findsOneWidget);
  });
}
