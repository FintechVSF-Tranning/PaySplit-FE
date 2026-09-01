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
    await tester.pumpWidget(const MaterialApp(home: ScanQrJoinPage()));
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
}
