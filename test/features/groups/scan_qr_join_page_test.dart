import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:paysplit/features/groups/presentation/pages/scan_qr_join_page.dart';

void main() {
  testWidgets('AC-1 AC-2 renders a live rear camera QR scanner', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ScanQrJoinPage()));
    await tester.pump();

    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    expect(scanner.controller, isNotNull);
    expect(scanner.controller!.facing, CameraFacing.back);
    expect(scanner.controller!.formats, const <BarcodeFormat>[
      BarcodeFormat.qrCode,
    ]);
    expect(find.text('Quét QR vào nhóm'), findsOneWidget);
  });

  testWidgets('AC-3 ignores duplicate detections while handling a QR value', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ScanQrJoinPage(scannerController: _ImmediateScannerController()),
      ),
    );
    await tester.pump();

    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    const capture = BarcodeCapture(
      barcodes: <Barcode>[
        Barcode(format: BarcodeFormat.qrCode, rawValue: 'not-a-paysplit-link'),
      ],
    );

    scanner.onDetect!(capture);
    scanner.onDetect!(capture);
    await tester.pump();

    expect(
      find.text('Mã QR này không phải lời mời vào nhóm PaySplit.'),
      findsOneWidget,
    );
  });

  testWidgets('AC-7 keeps image and manual link fallbacks available', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ScanQrJoinPage()));
    await tester.pump();

    expect(find.text('Chọn ảnh QR'), findsOneWidget);
    expect(find.text('Nhập link'), findsOneWidget);
    expect(find.byTooltip('Quay lại'), findsOneWidget);
    expect(find.byTooltip('Thiết bị không hỗ trợ đèn flash'), findsOneWidget);
  });

  testWidgets('waits for scanner start before disposing the web stream', (
    tester,
  ) async {
    final controller = _DelayedScannerController();

    await tester.pumpWidget(
      MaterialApp(home: ScanQrJoinPage(scannerController: controller)),
    );
    await tester.pump();
    expect(controller.events, <String>['start']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(controller.events, <String>['start']);

    controller.allowStartToFinish.complete();
    await tester.pump();
    await tester.pump();

    expect(controller.events, <String>['start', 'start complete', 'dispose']);
  });

  testWidgets('waits for camera tracks to stop before closing the QR page', (
    tester,
  ) async {
    final controller = _DelayedStopScannerController();

    await tester.pumpWidget(
      MaterialApp(home: _ScannerLauncher(controller: controller)),
    );
    await tester.tap(find.text('Open scanner'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pump();
    expect(find.byType(ScanQrJoinPage), findsOneWidget);
    expect(controller.events, contains('stop'));

    controller.allowStopToFinish.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(ScanQrJoinPage), findsNothing);
    expect(controller.events, contains('stop complete'));
  });
}

class _ScannerLauncher extends StatelessWidget {
  const _ScannerLauncher({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => ScanQrJoinPage(scannerController: controller),
            ),
          ),
          child: const Text('Open scanner'),
        ),
      ),
    );
  }
}

class _DelayedScannerController extends MobileScannerController {
  _DelayedScannerController() : super(autoStart: false);

  final Completer<void> allowStartToFinish = Completer<void>();
  final List<String> events = <String>[];

  @override
  Future<void> start({
    CameraFacing? cameraDirection,
    CameraLensType? cameraLensType,
  }) async {
    events.add('start');
    await allowStartToFinish.future;
    events.add('start complete');
  }

  @override
  Future<void> dispose() async {
    events.add('dispose');
    await super.dispose();
  }
}

class _ImmediateScannerController extends MobileScannerController {
  _ImmediateScannerController() : super(autoStart: false);

  @override
  Future<void> start({
    CameraFacing? cameraDirection,
    CameraLensType? cameraLensType,
  }) async {}

  @override
  Future<void> dispose() async {
    await super.dispose();
  }
}

class _DelayedStopScannerController extends MobileScannerController {
  _DelayedStopScannerController() : super(autoStart: false);

  final Completer<void> allowStopToFinish = Completer<void>();
  final List<String> events = <String>[];

  @override
  Future<void> start({
    CameraFacing? cameraDirection,
    CameraLensType? cameraLensType,
  }) async {
    events.add('start');
  }

  @override
  Future<void> stop() async {
    events.add('stop');
    await allowStopToFinish.future;
    events.add('stop complete');
  }

  @override
  Future<void> dispose() async {
    events.add('dispose');
    await super.dispose();
  }
}
