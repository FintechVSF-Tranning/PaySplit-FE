import '../../domain/entities/group_debt_entity.dart';

/// Nhãn đại diện người dùng hiện tại trong ma trận công nợ.
const String kMeLabel = 'Bạn';

/// Một khoản nợ thô từ `GET /api/v1/groups/{id}/debts`.
class RawGroupDebt {
  const RawGroupDebt({
    required this.id,
    required this.debtorId,
    required this.debtorName,
    required this.creditorId,
    required this.creditorName,
    required this.amount,
    required this.status,
    required this.billTitle,
  });

  final String id;
  final String debtorId;
  final String debtorName;
  final String creditorId;
  final String creditorName;
  final int amount;
  final String status;
  final String billTitle;

  /// Khoản còn phải xử lý: chưa trả, hoặc đã nộp minh chứng chờ duyệt.
  bool get isActive => status == 'awaiting' || status == 'pending_confirmation';

  bool get isAwaitingReview => status == 'pending_confirmation';

  factory RawGroupDebt.fromJson(Map<String, dynamic> json) {
    return RawGroupDebt(
      id: '${json['id'] ?? ''}',
      debtorId: '${json['debtor_member_id'] ?? ''}',
      debtorName: '${json['debtor_display_name'] ?? 'Thành viên'}',
      creditorId: '${json['creditor_member_id'] ?? ''}',
      creditorName: '${json['creditor_display_name'] ?? 'Thành viên'}',
      amount: _money(json['amount']),
      status: '${json['status'] ?? ''}',
      billTitle: '${json['merchant_name'] ?? 'Hóa đơn'}',
    );
  }

  static int _money(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

/// Kết quả gom công nợ cho tab "Công nợ" của một nhóm.
class GroupDebtsView {
  const GroupDebtsView({
    this.debts = const [],
    this.matrix = const [],
    this.debtIdsByCounterpart = const {},
    this.netBalanceByMember = const {},
  });

  /// Các khoản của **tôi**, đã gom theo từng người đối diện.
  final List<GroupDebtEntity> debts;

  /// Ma trận "ai trả ai" của cả nhóm.
  final List<DebtMatrixRow> matrix;

  /// ID các khoản nợ gốc theo `membership_id` của người đối diện — cần cho các
  /// hành động thật (nhắc nợ, tạo QR gộp).
  final Map<String, List<String>> debtIdsByCounterpart;

  /// Số dư ròng của từng thành viên, tính đúng công thức của view
  /// `v_member_balances` phía backend (tổng khoản được nhận trừ tổng khoản phải
  /// trả, chỉ tính khoản còn sống). Tính lại tại client để số dư đi theo mỗi
  /// lần tải lại công nợ, thay vì đứng yên từ lần đọc `GET /groups/{id}`.
  final Map<String, int> netBalanceByMember;
}

/// Gom danh sách nợ thô thành dữ liệu hiển thị của tab Công nợ.
///
/// Backend trả nợ theo từng hóa đơn; màn nhóm nói chuyện theo từng người, nên
/// các khoản cùng một người được cộng lại. Chỉ gom khoản còn "sống": khoản đã
/// tất toán hoặc đã xóa khi rời nhóm không còn là việc phải làm của ai.
GroupDebtsView buildGroupDebtsView({
  required List<RawGroupDebt> raw,
  required String callerMembershipId,
}) {
  final active = raw.where((d) => d.isActive).toList();

  final amountByCounterpart = <String, int>{};
  final directionByCounterpart = <String, DebtDirection>{};
  final nameByCounterpart = <String, String>{};
  final pendingProofByCounterpart = <String, bool>{};
  final idsByCounterpart = <String, List<String>>{};

  final matrixAmounts = <String, int>{};
  final matrixPairs = <String, (String from, String to)>{};
  final netBalanceByMember = <String, int>{};

  for (final debt in active) {
    netBalanceByMember[debt.creditorId] =
        (netBalanceByMember[debt.creditorId] ?? 0) + debt.amount;
    netBalanceByMember[debt.debtorId] =
        (netBalanceByMember[debt.debtorId] ?? 0) - debt.amount;

    final fromLabel = debt.debtorId == callerMembershipId ? kMeLabel : debt.debtorName;
    final toLabel = debt.creditorId == callerMembershipId ? kMeLabel : debt.creditorName;
    final pairKey = '${debt.debtorId}->${debt.creditorId}';
    matrixAmounts[pairKey] = (matrixAmounts[pairKey] ?? 0) + debt.amount;
    matrixPairs[pairKey] = (fromLabel, toLabel);

    final isMine = debt.debtorId == callerMembershipId;
    final isTheirs = debt.creditorId == callerMembershipId;
    if (!isMine && !isTheirs) continue;

    final counterpartId = isMine ? debt.creditorId : debt.debtorId;
    final counterpartName = isMine ? debt.creditorName : debt.debtorName;

    // Một cặp người có thể vừa nợ vừa được nợ qua nhiều hóa đơn khác nhau; cộng
    // dồn theo dấu rồi mới quyết định chiều để không hiện hai dòng ngược nhau.
    final signed = isMine ? -debt.amount : debt.amount;
    amountByCounterpart[counterpartId] = (amountByCounterpart[counterpartId] ?? 0) + signed;
    nameByCounterpart[counterpartId] = counterpartName;
    (idsByCounterpart[counterpartId] ??= []).add(debt.id);
    if (isTheirs && debt.isAwaitingReview) {
      pendingProofByCounterpart[counterpartId] = true;
    }
  }

  final debts = <GroupDebtEntity>[];
  for (final entry in amountByCounterpart.entries) {
    if (entry.value == 0) continue;
    final owesMe = entry.value > 0;
    final name = nameByCounterpart[entry.key] ?? 'Thành viên';
    directionByCounterpart[entry.key] = owesMe ? DebtDirection.owesMe : DebtDirection.iOwe;
    debts.add(
      GroupDebtEntity(
        id: entry.key,
        counterpartName: name,
        direction: directionByCounterpart[entry.key]!,
        amount: entry.value.abs(),
        note: owesMe ? '$name cần trả cho bạn' : 'Bạn cần trả cho $name',
        hasPendingProof: owesMe && (pendingProofByCounterpart[entry.key] ?? false),
      ),
    );
  }
  debts.sort((a, b) => b.amount.compareTo(a.amount));

  final matrix = <DebtMatrixRow>[];
  for (final entry in matrixAmounts.entries) {
    if (entry.value == 0) continue;
    final pair = matrixPairs[entry.key]!;
    matrix.add(DebtMatrixRow(from: pair.$1, to: pair.$2, amount: entry.value));
  }
  matrix.sort((a, b) => b.amount.compareTo(a.amount));

  return GroupDebtsView(
    debts: debts,
    matrix: matrix,
    debtIdsByCounterpart: idsByCounterpart,
    netBalanceByMember: netBalanceByMember,
  );
}
