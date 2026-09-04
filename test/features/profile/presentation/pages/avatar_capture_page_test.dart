import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/profile/presentation/pages/avatar_capture_page.dart';

Future<List<CameraDescription>> _noCameras() async => <CameraDescription>[];

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
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/image_picker'),
          (MethodCall methodCall) async => null,
        );
  });

  group('AvatarCapturePage Widget Tests', () {
    testWidgets(
      'renders fallback view and options when no cameras are available',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: AvatarCapturePage(loadAvailableCameras: _noCameras),
          ),
        );
        await tester.pump();

        // Tiêu đề thanh trên
        expect(find.text('Chụp ảnh đại diện'), findsOneWidget);

        // Thông báo khi không có camera
        expect(find.text('Không thể mở Camera'), findsOneWidget);
        expect(
          find.byKey(const Key('avatar-capture-fallback-gallery-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('avatar-capture-retry-button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'back button closes AvatarCapturePage',
      (tester) async {
        var didPop = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AvatarCapturePage(
                          loadAvailableCameras: _noCameras,
                        ),
                      ),
                    );
                    didPop = true;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final backButton = find.byKey(const Key('avatar-capture-back-button'));
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(didPop, isTrue);
      },
    );

    testWidgets(
      'retry button in fallback view can be tapped without error',
      (tester) async {
        var callCount = 0;
        Future<List<CameraDescription>> mockLoadCameras() async {
          callCount++;
          return <CameraDescription>[];
        }

        await tester.pumpWidget(
          MaterialApp(
            home: AvatarCapturePage(loadAvailableCameras: mockLoadCameras),
          ),
        );
        await tester.pump();

        final retryButton = find.byKey(const Key('avatar-capture-retry-button'));
        expect(retryButton, findsOneWidget);
        await tester.tap(retryButton);
        await tester.pump();

        expect(callCount, greaterThanOrEqualTo(2));
      },
    );

    testWidgets(
      'routes to crop page when initialPreviewBytes is provided and returns cropped bytes',
      (tester) async {
        Uint8List? popResult;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    popResult = await Navigator.of(context).push<Uint8List>(
                      MaterialPageRoute(
                        builder: (_) => AvatarCapturePage(
                          loadAvailableCameras: _noCameras,
                          initialPreviewBytes: _testPngBytes,
                          openCropPage: (ctx, bytes, isCam) async => _testPngBytes,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(popResult, equals(_testPngBytes));
      },
    );
  });
}
