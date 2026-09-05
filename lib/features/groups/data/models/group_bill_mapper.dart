import 'package:intl/intl.dart';

import '../../../bills/domain/entities/bill_entity.dart';
import '../../../bills/domain/entities/bill_list_page.dart';
import '../../domain/entities/group_bill_entity.dart';

final DateFormat _sameYearFormat = DateFormat('dd/MM · HH:mm');
final DateFormat _otherYearFormat = DateFormat('dd/MM/yyyy');

/// Trạng thái hóa đơn của backend map 1-1 sang trạng thái hiển thị trong nhóm.
GroupBillStatus mapBillStatus(BillStatus status) => switch (status) {
  BillStatus.draft => GroupBillStatus.draft,
  BillStatus.reviewed => GroupBillStatus.reviewed,
  BillStatus.finalized => GroupBillStatus.finalized,
  BillStatus.voided => GroupBillStatus.voided,
};

extension BillEntityToGroupBill on BillEntity {
  GroupBillEntity toGroupBill() {
    final date = (billDate ?? createdAt).toLocal();
    final now = DateTime.now();
    return GroupBillEntity(
      id: id,
      title: title,
      dateText: date.year == now.year
          ? _sameYearFormat.format(date)
          : _otherYearFormat.format(date),
      payerName: payerName.isEmpty ? 'Thành viên nhóm' : payerName,
      status: mapBillStatus(status),
      totalAmount: totalAmount,
      myShare: myShare,
      myShareStatus: switch (myShareStatus) {
        MyShareStatus.creditor => GroupBillShareStatus.creditor,
        MyShareStatus.pending => GroupBillShareStatus.pending,
        MyShareStatus.settled => GroupBillShareStatus.settled,
        MyShareStatus.none => GroupBillShareStatus.none,
      },
      isScanningOcr: ocrStatus.isRunning,
      ocrFailed: ocrStatus == OcrJobStatus.failed,
      paidMemberCount: paidMemberCount,
      memberCount: memberCount,
      version: version,
    );
  }
}

extension BillListPageToGroupBills on BillListPage {
  GroupBillsPage toGroupBillsPage() {
    return GroupBillsPage(
      bills: [for (final bill in bills) bill.toGroupBill()],
      counts: {
        for (final entry in counts.entries)
          mapBillStatus(entry.key): entry.value,
      },
      totalCount: totalCount,
      nextCursor: nextCursor,
    );
  }
}
