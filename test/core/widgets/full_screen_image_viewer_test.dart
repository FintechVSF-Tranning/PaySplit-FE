import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:paysplit/core/widgets/full_screen_image_viewer.dart';

void main() {
  group('FullScreenImageViewer', () {
    testWidgets('renders memory bytes image with title, subtitle and controls', (
      tester,
    ) async {
      final bytes = Uint8List.fromList(const [1, 2, 3]);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => FullScreenImageViewer.show(
                    context,
                    bytes: bytes,
                    title: 'Minh chứng chuyển tiền',
                    subtitle: 'receipt.png',
                  ),
                  child: const Text('Xem ảnh'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Xem ảnh'));
      await tester.pumpAndSettle();

      expect(find.byType(FullScreenImageViewer), findsOneWidget);
      expect(find.text('Minh chứng chuyển tiền'), findsOneWidget);
      expect(find.text('receipt.png'), findsOneWidget);
      expect(find.text('Chụm tay để thu phóng • Chạm đúp để phóng to'), findsOneWidget);
      expect(find.byIcon(HugeIcons.strokeRoundedRotateRight01), findsOneWidget);
      expect(find.byIcon(HugeIcons.strokeRoundedCancel01), findsOneWidget);

      // Rotate image
      await tester.tap(find.byIcon(HugeIcons.strokeRoundedRotateRight01));
      await tester.pumpAndSettle();

      final rotatedBoxFinder = find.byType(RotatedBox);
      expect(rotatedBoxFinder, findsOneWidget);
      final rotatedBox = tester.widget<RotatedBox>(rotatedBoxFinder);
      expect(rotatedBox.quarterTurns, 1);

      // Close dialog
      await tester.tap(find.byIcon(HugeIcons.strokeRoundedCancel01));
      await tester.pumpAndSettle();

      expect(find.byType(FullScreenImageViewer), findsNothing);
    });
  });
}
