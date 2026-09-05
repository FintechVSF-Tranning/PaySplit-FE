import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/app/theme/app_colors.dart';
import 'package:paysplit/app/theme/app_theme.dart';
import 'package:paysplit/features/home/presentation/widgets/app_bottom_nav_bar.dart';

/// Dựng thanh điều hướng dưới đúng theme thật của app, không phải `ThemeData`
/// mặc định của Flutter — bảng màu tối là của PaySplit nên test phải chạy qua
/// chính `AppTheme`.
Future<void> _pump(WidgetTester tester, {required Brightness brightness}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      home: Scaffold(
        bottomNavigationBar: AppBottomNavBar(currentIndex: 0, onTap: (_) {}),
      ),
    ),
  );
}

/// Nền của thanh nằm ở `Container` ngoài cùng bên trong [AppBottomNavBar].
Color _background(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(AppBottomNavBar),
          matching: find.byType(Container),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).color!;
}

/// Màu chữ của nhãn một tab, tức màu đã nội suy giữa active và inactive.
Color _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

void main() {
  group('AppBottomNavBar theo chế độ sáng/tối', () {
    testWidgets('chế độ tối không dùng nền trắng', (tester) async {
      await _pump(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      // Chính lỗi được báo: thanh trắng nguyên vẹn giữa giao diện tối.
      expect(_background(tester), isNot(Colors.white));
      expect(_background(tester), AppColors.darkSurface);
    });

    testWidgets('chế độ tối dùng chữ đủ tương phản trên nền tối', (
      tester,
    ) async {
      await _pump(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      expect(
        _labelColor(tester, 'Tổng quan'),
        AppColors.darkPrimary,
        reason: 'tab đang chọn phải dùng màu chủ đạo bản tối',
      );
      expect(
        _labelColor(tester, 'Nhóm'),
        AppColors.darkTextMuted,
        reason:
            'chữ mờ bản sáng (#676E5F) đặt trên nền #1B2019 gần như không đọc '
            'được',
      );
    });

    testWidgets('chế độ sáng giữ nguyên bảng màu cũ', (tester) async {
      await _pump(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();

      // Sửa dark mode không được kéo theo thay đổi nào cho giao diện sáng.
      expect(_background(tester), const Color(0xFFFFFFFF));
      expect(_labelColor(tester, 'Tổng quan'), const Color(0xFF0F766E));
      expect(_labelColor(tester, 'Nhóm'), const Color(0xFF676E5F));
    });

    testWidgets('viền trên đổi theo chế độ', (tester) async {
      await _pump(tester, brightness: Brightness.light);
      await tester.pumpAndSettle();
      final lightBorder =
          ((tester
                          .widget<Container>(
                            find
                                .descendant(
                                  of: find.byType(AppBottomNavBar),
                                  matching: find.byType(Container),
                                )
                                .first,
                          )
                          .decoration!
                      as BoxDecoration)
                  .border!
              as Border);
      expect(lightBorder.top.color, const Color(0xFFDBE0CE));

      await _pump(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();
      final darkBorder =
          ((tester
                          .widget<Container>(
                            find
                                .descendant(
                                  of: find.byType(AppBottomNavBar),
                                  matching: find.byType(Container),
                                )
                                .first,
                          )
                          .decoration!
                      as BoxDecoration)
                  .border!
              as Border);
      expect(darkBorder.top.color, AppColors.darkBorder);
    });
  });
}
