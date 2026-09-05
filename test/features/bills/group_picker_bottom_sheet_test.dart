import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/bills/presentation/widgets/group_picker_bottom_sheet.dart';

void main() {
  testWidgets('AC 3 nhóm đã khóa không thể được chọn để quét bill', (
    tester,
  ) async {
    GroupItemData? selected;
    const locked = GroupItemData(
      id: 'locked',
      name: 'Nhóm đã khóa',
      memberCount: 3,
      balanceText: '0 ₫',
      billSubmissionLocked: true,
    );
    const open = GroupItemData(
      id: 'open',
      name: 'Nhóm đang mở',
      memberCount: 2,
      balanceText: '0 ₫',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupPickerBottomSheet(
            selectedGroupId: '',
            groups: const [locked, open],
            onGroupSelected: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.textContaining('Đã khóa nhận bill'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.enabled == false &&
            w.properties.button == true,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Nhóm đã khóa'));
    expect(selected, isNull);

    await tester.tap(find.text('Nhóm đang mở'));
    expect(selected?.id, 'open');
  });
}
