import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:paysplit/core/widgets/full_screen_image_viewer.dart';
import 'package:paysplit/features/settlement/domain/entities/settlement_entities.dart';
import 'package:paysplit/features/settlement/presentation/widgets/dynamic_vietqr_sheet.dart';

void main() {
  group('DynamicVietQrSheet', () {
    testWidgets('picks proof, shows preview, allows note, and submits explicitly', (
      tester,
    ) async {
      final upload = Completer<void>();
      String? submittedNote;
      ProofUploadEntity? submittedImage;

      await tester.pumpWidget(
        _testApp(
          pickProof: () async => ProofUploadEntity(
            bytes: Uint8List.fromList(const [1, 2, 3]),
            name: 'receipt.png',
          ),
          onSubmitProof: (image, note) {
            submittedImage = image;
            submittedNote = note;
            return upload.future;
          },
        ),
      );
      await tester.tap(find.text('Mở VietQR'));
      await tester.pumpAndSettle();

      // 1. Initially no proof is selected
      expect(find.text('Tải lên ảnh minh chứng chuyển tiền'), findsOneWidget);
      expect(find.text('Tải ảnh biên lai đã chuyển'), findsOneWidget);

      // 2. Pick proof
      await tester.ensureVisible(find.text('Tải ảnh biên lai đã chuyển'));
      await tester.pump();
      await tester.tap(find.text('Tải ảnh biên lai đã chuyển'));
      await tester.pumpAndSettle();

      // 3. Proof is selected, preview is shown, but NOT yet submitted!
      expect(find.text('Đã chọn ảnh (chạm để xem)'), findsOneWidget);
      expect(find.text('receipt.png'), findsOneWidget);
      expect(find.text('Xác nhận đã chuyển tiền'), findsOneWidget);
      expect(submittedImage, isNull);

      // 4. Enter note
      await tester.enterText(
        find.byType(TextField),
        'Đã chuyển tiền qua VCB rồi nhé!',
      );
      await tester.pump();

      // 5. Explicitly tap "Xác nhận đã chuyển tiền" to submit
      await tester.tap(find.text('Xác nhận đã chuyển tiền'));
      await tester.pump();

      expect(submittedImage?.name, 'receipt.png');
      expect(submittedNote, 'Đã chuyển tiền qua VCB rồi nhé!');
      expect(find.byType(DynamicVietQrSheet), findsOneWidget);

      // 6. Completes upload and sheet closes
      upload.complete();
      await tester.pumpAndSettle();
      expect(find.byType(DynamicVietQrSheet), findsNothing);
    });

    testWidgets('shows an error and keeps the sheet open when upload fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          pickProof: () async => ProofUploadEntity(
            bytes: Uint8List.fromList(const [1, 2, 3]),
            name: 'receipt.jpg',
          ),
          onSubmitProof: (_, _) => Future<void>.error(StateError('offline')),
        ),
      );
      await tester.tap(find.text('Mở VietQR'));
      await tester.pumpAndSettle();

      // Pick proof
      await tester.ensureVisible(find.text('Tải ảnh biên lai đã chuyển'));
      await tester.pump();
      await tester.tap(find.text('Tải ảnh biên lai đã chuyển'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Xác nhận đã chuyển tiền'));
      await tester.pumpAndSettle();

      expect(find.byType(DynamicVietQrSheet), findsOneWidget);
      expect(find.byKey(const Key('proof-upload-error')), findsOneWidget);
      expect(find.textContaining('Không thể tải biên lai'), findsOneWidget);
    });

    testWidgets('rejects unsupported proof files before calling upload', (
      tester,
    ) async {
      var uploadCount = 0;
      await tester.pumpWidget(
        _testApp(
          pickProof: () async => ProofUploadEntity(
            bytes: Uint8List.fromList(const [1, 2, 3]),
            name: 'receipt.txt',
          ),
          onSubmitProof: (_, _) async => uploadCount += 1,
        ),
      );
      await tester.tap(find.text('Mở VietQR'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Tải ảnh biên lai đã chuyển'));
      await tester.pump();
      await tester.tap(find.text('Tải ảnh biên lai đã chuyển'));
      await tester.pumpAndSettle();

      expect(uploadCount, 0);
      expect(find.text('Chỉ hỗ trợ ảnh JPEG, PNG hoặc HEIC.'), findsOneWidget);
      expect(find.text('Tải ảnh biên lai đã chuyển'), findsOneWidget);
    });

    testWidgets('allows removing selected proof and selecting another', (
      tester,
    ) async {
      var pickedName = 'first.png';
      await tester.pumpWidget(
        _testApp(
          pickProof: () async => ProofUploadEntity(
            bytes: Uint8List.fromList(const [1, 2, 3]),
            name: pickedName,
          ),
          onSubmitProof: (_, _) async {},
        ),
      );
      await tester.tap(find.text('Mở VietQR'));
      await tester.pumpAndSettle();

      // Pick first proof
      await tester.ensureVisible(find.text('Tải ảnh biên lai đã chuyển'));
      await tester.pump();
      await tester.tap(find.text('Tải ảnh biên lai đã chuyển'));
      await tester.pumpAndSettle();
      expect(find.text('first.png'), findsOneWidget);

      // Remove proof
      await tester.tap(find.byTooltip('Gỡ ảnh'));
      await tester.pumpAndSettle();
      expect(find.text('first.png'), findsNothing);
      expect(find.text('Tải lên ảnh minh chứng chuyển tiền'), findsOneWidget);
      expect(find.text('Tải ảnh biên lai đã chuyển'), findsOneWidget);
    });

    testWidgets('tapping VietQR code opens FullScreenImageViewer', (tester) async {
      await tester.pumpWidget(
        _testApp(
          pickProof: () async => null,
          onSubmitProof: (_, _) async {},
        ),
      );
      await tester.tap(find.text('Mở VietQR'));
      await tester.pumpAndSettle();

      // Tap on QR code
      await tester.tap(find.byKey(const Key('vietqr-image')));
      await tester.pumpAndSettle();

      expect(find.text('Mã VietQR thanh toán'), findsOneWidget);
      expect(find.byIcon(HugeIcons.strokeRoundedCancel01), findsWidgets);

      // Close full screen viewer
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();

      expect(find.text('Mã VietQR thanh toán'), findsNothing);
      expect(find.byType(DynamicVietQrSheet), findsOneWidget);
    });

    testWidgets('tapping selected proof thumbnail opens FullScreenImageViewer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          pickProof: () async => ProofUploadEntity(
            bytes: Uint8List.fromList(const [1, 2, 3]),
            name: 'my_bill.jpg',
          ),
          onSubmitProof: (_, _) async {},
        ),
      );
      await tester.tap(find.text('Mở VietQR'));
      await tester.pumpAndSettle();

      // Pick proof
      await tester.ensureVisible(find.text('Tải ảnh biên lai đã chuyển'));
      await tester.pump();
      await tester.tap(find.text('Tải ảnh biên lai đã chuyển'));
      await tester.pumpAndSettle();

      // Tap on the selected proof
      await tester.tap(find.text('Đã chọn ảnh (chạm để xem)'));
      await tester.pumpAndSettle();

      expect(find.byType(FullScreenImageViewer), findsOneWidget);
      expect(find.text('Minh chứng chuyển tiền'), findsOneWidget);
      expect(find.text('my_bill.jpg'), findsWidgets);

      // Close full screen viewer
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();

      expect(find.byType(FullScreenImageViewer), findsNothing);
      expect(find.text('Minh chứng chuyển tiền'), findsNothing);
      expect(find.byType(DynamicVietQrSheet), findsOneWidget);
    });

    testWidgets('does not overflow on narrow screens like iPhone SE (375px and 320px width)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _testApp(
          pickProof: () async => ProofUploadEntity(
            bytes: Uint8List.fromList(const [1, 2, 3]),
            name: 'very_long_file_name_for_receipt_proof_image.png',
          ),
          onSubmitProof: (_, _) async {},
        ),
      );
      await tester.tap(find.text('Mở VietQR'));
      await tester.pumpAndSettle();

      final uploadBtn = find.text('Tải ảnh biên lai đã chuyển');
      await tester.ensureVisible(uploadBtn);
      await tester.pump();
      await tester.tap(uploadBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Đã chọn ảnh'), findsOneWidget);
    });
  });
}

Widget _testApp({
  required ProofPicker pickProof,
  required Future<void> Function(ProofUploadEntity image, String? note)
  onSubmitProof,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => DynamicVietQrSheet(
                  payment: const PaymentQrEntity(
                    id: 'payment-1',
                    groupId: 'group-1',
                    amount: 120000,
                    referenceCode: 'PAYABCDEFGH',
                    qrPayload: 'vietqr-payload',
                    qrImageUrl: 'https://example.com/qr.png',
                    bankName: 'Vietcombank',
                    accountNumber: '123456789',
                    accountHolder: 'NGUYEN VAN A',
                    coveredDebtIds: ['debt-1'],
                  ),
                  creditorName: 'Nguyễn Văn A',
                  pickProof: pickProof,
                  onSubmitProof: onSubmitProof,
                ),
              ),
              child: const Text('Mở VietQR'),
            ),
          ),
        ),
      ),
    ),
  );
}
