import '../../domain/entities/group_activity_entity.dart';
import '../../domain/entities/group_bill_entity.dart';
import '../../domain/entities/group_debt_entity.dart';
import '../../domain/entities/group_detail_entity.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_member_entity.dart';

/// Dữ liệu mocup cho màn Chi tiết nhóm, bám theo prototype `PaySplit-UI`
/// (`#screen-group-hub`). Khi có API thật, thay bằng
/// `GET /api/v1/groups/{id}` + các endpoint bills/debts/members/activities.
abstract class GroupDetailMockData {
  /// Dựng detail cho bất kỳ nhóm nào: giữ nguyên danh tính nhóm truyền vào,
  /// phần nội dung 4 tab dùng bộ dữ liệu mẫu chung.
  static GroupDetailEntity detailOf(GroupEntity group) {
    return GroupDetailEntity(
      group: group,
      createdAtText: 'tạo ngày 15/08',
      bills: _bills,
      debts: _debts,
      debtMatrix: _debtMatrix,
      members: _membersFor(group),
      activities: _activitiesFor(group),
    );
  }

  static const List<GroupBillEntity> _bills = [
    GroupBillEntity(
      id: 'b_001',
      title: 'Lẩu gà lá é Tao Ngộ',
      dateText: '15/08/2026',
      payerName: 'Nam',
      status: GroupBillStatus.settled,
      totalAmount: 850000,
      myShare: 212500,
      paidMemberCount: 4,
      memberCount: 5,
    ),
    GroupBillEntity(
      id: 'b_002',
      title: 'Cà phê planning',
      dateText: 'Hôm nay',
      payerName: 'Linh',
      status: GroupBillStatus.ocrScanning,
      totalAmount: 245000,
      paidMemberCount: 0,
      memberCount: 5,
    ),
    GroupBillEntity(
      id: 'b_003',
      title: 'Ăn trưa sprint review',
      dateText: '13/08/2026',
      payerName: 'Minh',
      status: GroupBillStatus.settled,
      totalAmount: 529200,
      myShare: 132300,
      paidMemberCount: 5,
      memberCount: 5,
    ),
    GroupBillEntity(
      id: 'b_004',
      title: 'Tiệc tổng kết quý',
      dateText: '10/08/2026',
      payerName: 'Nam',
      status: GroupBillStatus.awaitingAllocation,
      totalAmount: 1240000,
      paidMemberCount: 0,
      memberCount: 5,
    ),
  ];

  static const List<GroupDebtEntity> _debts = [
    GroupDebtEntity(
      id: 'd_001',
      counterpartName: 'Trần Lâm',
      direction: DebtDirection.iOwe,
      amount: 120000,
      note: 'Bạn cần trả cho Lâm',
      transferRef: 'PAY-DEV-LAM',
    ),
    GroupDebtEntity(
      id: 'd_002',
      counterpartName: 'Minh Tran',
      direction: DebtDirection.owesMe,
      amount: 280000,
      note: 'Minh đã nộp minh chứng',
      hasPendingProof: true,
    ),
  ];

  static const List<DebtMatrixRow> _debtMatrix = [
    DebtMatrixRow(from: 'Trần Lâm', to: 'Bạn', amount: 120000),
    DebtMatrixRow(from: 'Minh Tran', to: 'Bạn', amount: 280000),
  ];

  static List<GroupMemberBalance> _membersFor(GroupEntity group) {
    const roster = [
      (name: 'Hoàng Nam', phone: '0901 234 567', balance: 350000, isMe: true, captain: true),
      (name: 'Minh Tran', phone: '0912 888 121', balance: -280000, isMe: false, captain: false),
      (name: 'Trần Lâm', phone: '0987 654 321', balance: -120000, isMe: false, captain: false),
      (name: 'Linh Nguyễn', phone: '0938 445 902', balance: 0, isMe: false, captain: false),
      (name: 'Đức Huy', phone: '0977 310 654', balance: 50000, isMe: false, captain: false),
    ];

    // Cắt roster theo đúng sĩ số của nhóm để 2 con số không mâu thuẫn nhau.
    final take = group.memberCount.clamp(1, roster.length);
    return [
      for (var i = 0; i < take; i++)
        GroupMemberBalance(
          member: GroupMemberEntity(
            id: 'm_${i + 1}',
            name: roster[i].name,
            phone: roster[i].phone,
            role: roster[i].captain ? GroupMemberRole.captain : GroupMemberRole.member,
          ),
          balance: roster[i].balance,
          isMe: roster[i].isMe,
        ),
    ];
  }

  static List<GroupActivityEntity> _activitiesFor(GroupEntity group) => [
    const GroupActivityEntity(
      id: 'a_001',
      title: 'Minh Tran đã nộp minh chứng 280.000 đ',
      subtitle: 'Chờ Hoàng Nam duyệt proof',
      timeText: '5 phút trước',
      kind: GroupActivityKind.payment,
    ),
    const GroupActivityEntity(
      id: 'a_002',
      title: 'Cà phê planning đang được quét OCR',
      subtitle: 'Linh Nguyễn đã gửi 2 ảnh hóa đơn',
      timeText: '32 phút trước',
      kind: GroupActivityKind.bill,
    ),
    const GroupActivityEntity(
      id: 'a_003',
      title: 'Lẩu gà lá é đã chốt chia tiền',
      subtitle: '4 trên 5 thành viên đã thanh toán',
      timeText: 'Hôm qua',
      kind: GroupActivityKind.bill,
    ),
    GroupActivityEntity(
      id: 'a_004',
      title: 'Nhóm ${group.name} được tạo',
      subtitle: 'Hoàng Nam là trưởng nhóm',
      timeText: '15/08/2026',
      kind: GroupActivityKind.system,
    ),
  ];

  /// Các lô hoạt động tải thêm khi bấm "Tải thêm hoạt động".
  static const List<GroupActivityEntity> moreActivities = [
    GroupActivityEntity(
      id: 'a_005',
      title: 'Trần Lâm đã tham gia nhóm',
      subtitle: 'Qua link mời của Hoàng Nam',
      timeText: '14/08/2026',
      kind: GroupActivityKind.member,
    ),
    GroupActivityEntity(
      id: 'a_006',
      title: 'Ăn trưa sprint review đã chốt chia tiền',
      subtitle: 'Tổng 529.200 đ chia cho 5 người',
      timeText: '13/08/2026',
      kind: GroupActivityKind.bill,
    ),
  ];
}
