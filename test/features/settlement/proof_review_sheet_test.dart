import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/widgets/full_screen_image_viewer.dart';
import 'package:paysplit/features/settlement/domain/entities/settlement_entities.dart';
import 'package:paysplit/features/settlement/presentation/widgets/proof_review_sheet.dart';

void main() {
  group('ProofReviewSheet', () {
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
