import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paysplit/core/widgets/full_screen_image_viewer.dart';
import 'package:paysplit/features/settlement/domain/entities/settlement_entities.dart';
import 'package:paysplit/features/settlement/presentation/widgets/proof_review_sheet.dart';

class _PendingImageClient extends Mock implements HttpClient {}

void main() {
  group('ProofReviewSheet', () {
    testWidgets('shows loading before the image server sends any bytes', (
      tester,
    ) async {
      final client = _PendingImageClient();
      final pending = Completer<HttpClientRequest>();
      when(
        () => client.getUrl(Uri.parse('https://example.com/pending.webp')),
      ).thenAnswer((_) => pending.future);
      debugNetworkImageHttpClientProvider = () => client;
      addTearDown(() => debugNetworkImageHttpClientProvider = null);
      final proof = ProofDetailEntity(
        id: 'proof-pending',
        groupId: 'group-1',
        groupName: 'Nhóm',
        paymentId: 'payment-1',
        debtorName: 'Người trả',
        debtorAvatar: '',
        creditorName: 'Người nhận',
        amount: 100000,
        targetBank: 'VCB',
        targetAccount: '123',
        referenceCode: 'PAY123',
        submittedAt: DateTime(2026, 9, 6),
        proofImageUrl: 'https://example.com/pending.webp',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProofReviewSheet(proof: proof)),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Đang tải ảnh biên lai…'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('renders proof details and tapping image opens FullScreenImageViewer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final proof = ProofDetailEntity(
        id: 'proof-1',
        groupId: 'group-1',
        groupName: 'Nhóm Ăn Trưa',
        paymentId: 'pay-123',
        debtorName: 'Trần Thị B',
        debtorAvatar: 'https://example.com/avatar.jpg',
        creditorName: 'Nguyễn Văn A',
        amount: 85000,
        targetBank: 'Vietcombank',
        targetAccount: '987654321',
        referenceCode: 'SPLIT999',
        submittedAt: DateTime(2026, 8, 27, 10, 30),
        proofImageUrl: 'https://example.com/receipt.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ProofReviewSheet(proof: proof),
                  ),
                  child: const Text('Mở duyệt proof'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở duyệt proof'));
      await tester.pumpAndSettle();

      expect(find.byType(ProofReviewSheet), findsOneWidget);
      expect(find.text('Duyệt bằng chứng chuyển tiền'), findsOneWidget);
      expect(find.text('Chạm để phóng to'), findsOneWidget);

      // Tap on proof image
      await tester.tap(find.byKey(const Key('proof-image')));
      await tester.pumpAndSettle();

      expect(find.byType(FullScreenImageViewer), findsOneWidget);
      expect(find.text('Bằng chứng chuyển tiền'), findsOneWidget);

      // Close full screen viewer
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();

      expect(find.byType(FullScreenImageViewer), findsNothing);
      expect(find.byType(ProofReviewSheet), findsOneWidget);
    });
  });
}
