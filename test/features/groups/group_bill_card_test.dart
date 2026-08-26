import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:paysplit/features/groups/domain/entities/group_bill_entity.dart';
import 'package:paysplit/features/groups/presentation/widgets/group_bill_card.dart';

GroupBillEntity _bill({GroupBillStatus status = GroupBillStatus.draft}) {
  return GroupBillEntity(
    id: 'bill-1',
    title: 'Bách Hóa Xanh',
    dateText: '26/08 · 14:24',
    payerName: 'Le Van Cuong',
    status: status,
    totalAmount: 322130,
    paidMemberCount: 0,
    memberCount: 0,
  );
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  final trashIcon = find.byIcon(HugeIcons.strokeRoundedDelete02);

  testWidgets('thành viên thường không thấy nút xóa hóa đơn', (tester) async {
    await _pump(tester, GroupBillCard(bill: _bill()));

    expect(trashIcon, findsNothing);
  });

  testWidgets('trưởng nhóm thấy nút xóa và bấm được', (tester) async {
    var tapped = 0;
    await _pump(
      tester,
      GroupBillCard(bill: _bill(), onDelete: () => tapped++),
    );

    expect(trashIcon, findsOneWidget);

    await tester.tap(trashIcon);
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('bấm nút xóa không mở luôn chi tiết hóa đơn', (tester) async {
    var opened = 0;
    var deleted = 0;
    await _pump(
      tester,
      GroupBillCard(
        bill: _bill(),
        onTap: () => opened++,
        onDelete: () => deleted++,
      ),
    );

    await tester.tap(trashIcon);
    await tester.pump();

    expect(deleted, 1);
    expect(opened, 0, reason: 'thao tác phá hủy không được kèm điều hướng');
  });
}
