import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:paysplit/features/home/presentation/widgets/group_settings_bottom_sheet.dart';

void main() {
  group('GroupSettingsBottomSheet Widget Tests', () {
    const members = [
      GroupMemberSettingItem(
        membershipId: 'mem-1',
        userId: 'u-1',
        displayName: 'User 1 (Captain)',
        role: 'captain',
        isCurrentUser: true,
      ),
      GroupMemberSettingItem(
        membershipId: 'mem-2',
        userId: 'u-2',
        displayName: 'User 2',
        role: 'member',
      ),
      GroupMemberSettingItem(
        membershipId: 'mem-3',
        userId: 'u-3',
        displayName: 'User 3',
        role: 'member',
      ),
    ];

    testWidgets('Renders scaled icon-only buttons for actions without label text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroupSettingsBottomSheet(
              groupId: 'g-1',
              initialGroupName: 'Ăn trưa 27/8',
              createdAtText: '27/08/2026',
              isCaptain: true,
              currentUserNetBalance: 0,
              members: members,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header & section titles
      expect(find.text('Cài đặt nhóm'), findsOneWidget);
      expect(find.text('Ăn trưa 27/8'), findsOneWidget);
      expect(find.text('THÀNH VIÊN (3)'), findsOneWidget);
      expect(find.text('TRẠNG THÁI BILL'), findsOneWidget);
      expect(find.text('VÙNG NGUY HIỂM'), findsOneWidget);

      // Icon-only buttons should exist
      expect(find.byIcon(HugeIcons.strokeRoundedUserRemove01), findsNWidgets(2)); // for 2 non-captain members
      expect(find.byIcon(HugeIcons.strokeRoundedLogout01), findsOneWidget);
      expect(find.byIcon(HugeIcons.strokeRoundedDelete02), findsOneWidget);
      expect(find.byIcon(HugeIcons.strokeRoundedEdit02), findsOneWidget);
      expect(find.byIcon(HugeIcons.strokeRoundedExchange01), findsOneWidget);

      // Plain button label texts should NOT be rendered
      expect(find.widgetWithText(OutlinedButton, 'Xóa'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Rời nhóm'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Giải tán'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Đổi tên'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Chuyển Trưởng nhóm'), findsNothing);
    });
  });
}
