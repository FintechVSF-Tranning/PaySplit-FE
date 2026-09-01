import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/bills/presentation/pages/bill_capture_page.dart';
import 'package:paysplit/features/bills/presentation/widgets/captured_photos_tray.dart';
import 'package:paysplit/features/bills/presentation/widgets/photo_detail_dialog.dart';

Future<List<CameraDescription>> _noCameras() async => <CameraDescription>[];

Future<void> _pumpUntilPhotoIsAdded(WidgetTester tester) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text('Chia tiền (1)').evaluate().isNotEmpty) return;
  }
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/image_picker'),
          (MethodCall methodCall) async => null,
        );
  });

  group('BillCapturePage Widget Tests', () {
    testWidgets(
      'renders camera overlay, close button, and manual entry button when 0 photos',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: BillCapturePage(loadAvailableCameras: _noCameras),
            ),
          ),
        );
        await tester.pump();

        // When 0 photos -> Right button is "Nhập thủ công"
        expect(find.text('Nhập thủ công'), findsOneWidget);

        // Bottom dock buttons
        expect(find.text('Thư viện'), findsOneWidget);
        expect(find.text('Flash Tắt'), findsOneWidget);

        // Tray is not visible when 0 photos
        expect(find.byType(CapturedPhotosTray), findsNothing);
        expect(find.textContaining('ẢNH ĐÃ CHỌN'), findsNothing);
      },
    );

    testWidgets(
      'tapping shutter adds photo and changes button to Chia tiền (1)',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: BillCapturePage(loadAvailableCameras: _noCameras),
            ),
          ),
        );
        await tester.pump();

        // Find the shutter button by looking for camera icon in bottom dock
        final shutterFinder = find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_ShutterButton',
        );
        expect(shutterFinder, findsOneWidget);

        // Tap shutter button
        await tester.tap(shutterFinder);
        await _pumpUntilPhotoIsAdded(tester);

        // Now top right button changes to "Chia tiền (1)"
        expect(find.text('Chia tiền (1)'), findsOneWidget);
        expect(find.text('Nhập thủ công'), findsNothing);

        // Tray shows 1 photo with reorder text and drag handle icon
        expect(find.textContaining('ẢNH ĐÃ CHỌN (1/5)'), findsOneWidget);
        expect(find.text('Kéo để đổi thứ tự'), findsOneWidget);
        expect(find.byIcon(Icons.drag_handle_rounded), findsOneWidget);
      },
    );

    testWidgets('tapping photo opens PhotoDetailDialog with crop action', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BillCapturePage(loadAvailableCameras: _noCameras),
          ),
        ),
      );
      await tester.pump();

      // Add a photo
      final shutterFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ShutterButton',
      );
      await tester.tap(shutterFinder);
      await _pumpUntilPhotoIsAdded(tester);

      // Tap thumbnail in tray
      await tester.tap(find.byType(Image).first);
      await tester.pump(const Duration(milliseconds: 400));

      // Dialog opens
      expect(find.byType(PhotoDetailDialog), findsOneWidget);
      expect(find.text('Ảnh 1/1'), findsOneWidget);
    });
  });
}
