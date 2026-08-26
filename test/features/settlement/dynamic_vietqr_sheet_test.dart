import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/settlement/domain/entities/settlement_entities.dart';
import 'package:paysplit/features/settlement/presentation/widgets/dynamic_vietqr_sheet.dart';

void main() {
  group('DynamicVietQrSheet', () {
    testWidgets('keeps the sheet open until proof upload completes', (
      tester,
    ) async {
      final upload = Completer<void>();
      await tester.pumpWidget(
        _testApp(
          pickProof: () async => ProofUploadEntity(
            bytes: Uint8List.fromList(const [1, 2, 3]),
            name: 'receipt.png',
          ),
          onSubmitProof: (_, _) => upload.future,
        ),
      );
      await tester.tap(find.text('Mở VietQR'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Tải ảnh biên lai đã chuyển'));
      await tester.pump();
      await tester.tap(find.text('Tải ảnh biên lai đã chuyển'));
      await tester.pump();

      expect(find.byType(DynamicVietQrSheet), findsOneWidget);
      expect(find.text('Tải ảnh biên lai đã chuyển'), findsNothing);

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

      await tester.ensureVisible(find.text('Tải ảnh biên lai đã chuyển'));
      await tester.pump();
      await tester.tap(find.text('Tải ảnh biên lai đã chuyển'));
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
