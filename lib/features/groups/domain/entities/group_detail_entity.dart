import 'package:equatable/equatable.dart';

import 'group_activity_entity.dart';
import 'group_bill_entity.dart';
import 'group_debt_entity.dart';
import 'group_entity.dart';
import 'group_member_entity.dart';

/// Số dư riêng của một thành viên bên trong nhóm.
class GroupMemberBalance extends Equatable {
  const GroupMemberBalance({required this.member, required this.balance, this.isMe = false});

  final GroupMemberEntity member;

  /// Dương = được nhận lại, âm = còn nợ nhóm.
  final int balance;
  final bool isMe;

  @override
  List<Object?> get props => [member, balance, isMe];
}

/// Toàn bộ dữ liệu của màn Chi tiết nhóm (Group Hub), gộp 4 tab.
class GroupDetailEntity extends Equatable {
  const GroupDetailEntity({
    required this.group,
    required this.createdAtText,
    required this.bills,
    required this.debts,
    required this.debtMatrix,
    required this.members,
    required this.activities,
  });

  final GroupEntity group;
  final String createdAtText;
  final List<GroupBillEntity> bills;
  final List<GroupDebtEntity> debts;
  final List<DebtMatrixRow> debtMatrix;
  final List<GroupMemberBalance> members;
  final List<GroupActivityEntity> activities;

  /// Tổng số tiền còn phải luân chuyển để nhóm sạch nợ.
  int get outstandingTotal => debtMatrix.fold(0, (sum, row) => sum + row.amount);

  int countBills(GroupBillFilter filter) => bills.where((b) => filter.matches(b.status)).length;

  @override
  List<Object?> get props => [group, bills, debts, members, activities];
}
