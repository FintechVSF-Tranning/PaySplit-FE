import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/profile/presentation/pages/avatar_crop_page.dart';

final Uint8List _testPngBytes = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

void main() {
  group('AvatarCropPage Widget Tests', () {
    testWidgets('renders crop UI with circular frame and control buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AvatarCropPage(
            imageBytes: _testPngBytes,
            isFromCamera: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Căn chỉnh ảnh đại diện'), findsOneWidget);
      expect(find.text('Kéo hoặc thu phóng để căn chỉnh'), findsOneWidget);
      expect(find.text('Chụp lại'), findsOneWidget);
      expect(find.text('Dùng ảnh này'), findsOneWidget);
      expect(find.byKey(const Key('avatar-crop-reset-button')), findsOneWidget);
      expect(find.byKey(const Key('avatar-crop-gesture-area')), findsOneWidget);
    });

    testWidgets('shows Hủy when isFromCamera is false (gallery pick)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AvatarCropPage(
            imageBytes: _testPngBytes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Dùng ảnh này'), findsOneWidget);
    });

    testWidgets('back button and cancel button pop page with null', (tester) async {
      var didPop = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  final res = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AvatarCropPage(
                        imageBytes: _testPngBytes,
                        isFromCamera: true,
                      ),
                    ),
                  );
                  if (res == null) didPop = true;
                },
                child: const Text('Open Crop'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Crop'));
      await tester.pumpAndSettle();

      // Nhấn nút cancel 'Chụp lại'
      final cancelBtn = find.byKey(const Key('avatar-crop-cancel-button'));
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(didPop, isTrue);
    });

    testWidgets('confirm button triggers crop and returns cropped bytes', (tester) async {
      Uint8List? cropResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  cropResult = await Navigator.of(context).push<Uint8List>(
                    MaterialPageRoute(
                      builder: (_) => AvatarCropPage(
                        imageBytes: _testPngBytes,
                        isFromCamera: true,
                        customCropWorker: (raw, rect) async => _testPngBytes,
                      ),
                    ),
                  );
                },
                child: const Text('Open Crop'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Crop'));
      await tester.pumpAndSettle();

      final confirmBtn = find.byKey(const Key('avatar-crop-confirm-button'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(cropResult, equals(_testPngBytes));
    });

    testWidgets('reset button and gesture interactions do not throw', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AvatarCropPage(
            imageBytes: _testPngBytes,
            isFromCamera: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gestureArea = find.byKey(const Key('avatar-crop-gesture-area'));
      expect(gestureArea, findsOneWidget);

      // Kéo ảnh
      await tester.drag(gestureArea, const Offset(30, -20));
      await tester.pump();

      // Nhấn nút Reset
      final resetBtn = find.byKey(const Key('avatar-crop-reset-button'));
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Căn chỉnh ảnh đại diện'), findsOneWidget);
    });
  });
}
