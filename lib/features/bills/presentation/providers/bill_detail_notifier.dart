import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/session/session_scope.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/realtime/realtime_interest.dart';
import '../../../../core/realtime/register_realtime_interest.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/bill_detail_entity.dart';
import '../../domain/entities/bill_entity.dart' show OcrJobStatus;
import '../../domain/entities/captured_bill_photo.dart';
import '../../domain/repositories/bill_repository.dart';

/// Kết quả thao tác chốt sổ hoá đơn (Finalize Bill)
enum FinalizeBillStatus { success, versionConflict, failed }

class FinalizeBillResult {
  final FinalizeBillStatus status;
  final String? message;

  const FinalizeBillResult.success()
    : status = FinalizeBillStatus.success,
      message = null;

  const FinalizeBillResult.versionConflict([this.message])
    : status = FinalizeBillStatus.versionConflict;

  const FinalizeBillResult.failed(this.message)
    : status = FinalizeBillStatus.failed;

  bool get isSuccess => status == FinalizeBillStatus.success;
  bool get isVersionConflict => status == FinalizeBillStatus.versionConflict;
}

class BillDetailState {
  final BillDetailEntity bill;
  final List<BillShareBreakdownEntity> breakdown;
  final bool isLoading;
  final bool isRefreshing;
  final bool isSaving;
  final bool isFinalizing;
  final bool isCalculatingBreakdown;
  final bool isOcrScanning;
  final String? ocrScanStep;
  final BillDetailEntity? ocrCandidate;
  final String? ocrErrorMessage;
  final String? errorMessage;
  final String? successMessage;
  final String? currentUserId;
  final Set<String>? evenSplitMemberIds;
  final bool isDirty;
  final bool isVoiding;
  final bool isDeleting;

  const BillDetailState({
    required this.bill,
    this.breakdown = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isSaving = false,
    this.isFinalizing = false,
    this.isCalculatingBreakdown = false,
    this.isOcrScanning = false,
    this.ocrScanStep,
    this.ocrCandidate,
    this.ocrErrorMessage,
    this.errorMessage,
    this.successMessage,
    this.currentUserId,
    this.evenSplitMemberIds,
    this.isDirty = false,
    this.isVoiding = false,
    this.isDeleting = false,
  });

  BillDetailState copyWith({
    BillDetailEntity? bill,
    List<BillShareBreakdownEntity>? breakdown,
    bool? isLoading,
    bool? isRefreshing,
    bool? isSaving,
    bool? isFinalizing,
    bool? isCalculatingBreakdown,
    bool? isOcrScanning,
    String? ocrScanStep,
    BillDetailEntity? ocrCandidate,
    bool clearOcrCandidate = false,
    bool clearOcrScanStep = false,
    String? ocrErrorMessage,
    String? errorMessage,
    String? successMessage,
    String? currentUserId,
    Set<String>? evenSplitMemberIds,
    bool? isDirty,
    bool? isVoiding,
    bool? isDeleting,
  }) {
    return BillDetailState(
      bill: bill ?? this.bill,
      breakdown: breakdown ?? this.breakdown,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSaving: isSaving ?? this.isSaving,
      isFinalizing: isFinalizing ?? this.isFinalizing,
      isCalculatingBreakdown:
          isCalculatingBreakdown ?? this.isCalculatingBreakdown,
      isOcrScanning: isOcrScanning ?? this.isOcrScanning,
      ocrScanStep: clearOcrScanStep ? null : (ocrScanStep ?? this.ocrScanStep),
      ocrCandidate: clearOcrCandidate
          ? null
          : (ocrCandidate ?? this.ocrCandidate),
      ocrErrorMessage: ocrErrorMessage,
      errorMessage: errorMessage,
      successMessage: successMessage,
      currentUserId: currentUserId ?? this.currentUserId,
      evenSplitMemberIds: evenSplitMemberIds ?? this.evenSplitMemberIds,
      isDirty: isDirty ?? this.isDirty,
      isVoiding: isVoiding ?? this.isVoiding,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }

  /// Kiểm tra xem có bất kỳ tiến trình xử lý API/tác vụ nào đang chạy hay không
  /// (Chống double-tap hoặc race condition giữa các thao tác chéo nhau)
  bool get isProcessing =>
      isLoading ||
      isSaving ||
      isFinalizing ||
      isVoiding ||
      isDeleting ||
      isCalculatingBreakdown ||
      isOcrScanning;

  /// Danh sách ID thành viên đang tham gia chia đều (mặc định là tất cả thành viên)
  Set<String> get activeEvenSplitMemberIds {
    if (evenSplitMemberIds != null && evenSplitMemberIds!.isNotEmpty) {
      return evenSplitMemberIds!;
    }
    return bill.members.map((m) => m.memberId).toSet();
  }

  /// Số tiền tạm tính chia đều trên mỗi người
  int get evenPerPersonAmount {
    final count = activeEvenSplitMemberIds.length;
    if (count == 0) return computedTotal;
    return (computedTotal / count).round();
  }

  /// Số lượng món chưa được gán cho ai trong nhóm
  int get unassignedCount =>
      bill.items.where((i) => i.assignments.isEmpty).length;

  /// Kiểm tra xem user hiện tại có phải là Chủ chi của hoá đơn hay không
  bool get isCurrentUserCreditor {
    if (myShare != null) {
      return myShare!.isCreditor;
    }
    final myMember = bill.members.cast<BillMemberEntity?>().firstWhere(
      (m) =>
          currentUserId != null &&
          m?.userId.isNotEmpty == true &&
          m?.userId == currentUserId,
      orElse: () => null,
    );
    if (myMember != null && bill.creditorMemberId.isNotEmpty) {
      return myMember.memberId == bill.creditorMemberId;
    }
    return false;
  }

  /// Tính toán số tiền thực tế của user hiện tại từ breakdown chính thức
  BillShareBreakdownEntity? get myShare {
    if (breakdown.isEmpty) return null;
    return breakdown.firstWhere(
      (b) =>
          (currentUserId != null && b.userId == currentUserId) ||
          b.memberId == bill.creditorMemberId,
      orElse: () => breakdown.first,
    );
  }

  /// Số tiền thực tế/tạm tính của user hiện tại (ưu tiên breakdown BE, nếu chưa có thì tạm tính trên client)
  int get myShareAmount {
    if (breakdown.isNotEmpty && myShare != null) {
      return myShare!.finalAmount;
    }

    if (bill.members.isEmpty) {
      return computedTotal;
    }

    final myMember = bill.members.cast<BillMemberEntity?>().firstWhere(
      (m) =>
          currentUserId != null &&
          m?.userId.isNotEmpty == true &&
          m?.userId == currentUserId,
      orElse: () => bill.members.cast<BillMemberEntity?>().firstWhere(
        (m) => m?.memberId == bill.creditorMemberId,
        orElse: () => bill.members.isNotEmpty ? bill.members.first : null,
      ),
    );

    if (myMember == null) return computedTotal;

    if (bill.splitMethod == 'even') {
      final selectedIds = activeEvenSplitMemberIds;
      if (!selectedIds.contains(myMember.memberId)) {
        return 0; // Không tham gia chia đều
      }
      final count = selectedIds.length;
      if (count == 0) return computedTotal;
      return (computedTotal / count).round();
    }

    // item_ratio: Tổng các món gán cho user + tỷ lệ phụ thu/VAT/giảm giá
    double myItemSum = 0;
    for (final item in bill.items) {
      final totalWeight = item.assignments.fold<double>(
        0,
        (s, a) => s + a.weight,
      );
      final myAssignment = item.assignments
          .cast<BillItemAssignmentEntity?>()
          .firstWhere(
            (a) => a?.memberId == myMember.memberId,
            orElse: () => null,
          );
      if (myAssignment != null && totalWeight > 0) {
        myItemSum += (item.finalPrice * (myAssignment.weight / totalWeight));
      }
    }

    if (computedNetItemsTotal > 0) {
      final ratio = myItemSum / computedNetItemsTotal;
      final adjustmentShare =
          (bill.serviceCharge + bill.vat - bill.generalDiscount) * ratio;
      final total = (myItemSum + adjustmentShare).round();
      return total > 0 ? total : 0;
    }

    return myItemSum.round();
  }

  /// Tổng tính toán của tất cả các món gốc (Gross Subtotal = sum(line_total))
  int get computedGrossSubtotal {
    return bill.items.fold(0, (sum, i) => sum + i.lineTotal);
  }

  /// Tổng khuyến mãi theo từng món (sum(discount_amount))
  int get computedTotalItemDiscount {
    return bill.items.fold(0, (sum, i) => sum + i.discountAmount);
  }

  /// Tổng tiền món thực tế sau giảm giá riêng (sum(final_price))
  int get computedNetItemsTotal {
    return computedGrossSubtotal - computedTotalItemDiscount;
  }

  /// Tổng tính toán toàn bộ hoá đơn = Net Items + Service Charge + VAT - General Discount
  int get computedTotal {
    final total =
        computedNetItemsTotal +
        bill.serviceCharge +
        bill.vat -
        bill.generalDiscount;
    return total > 0 ? total : 0;
  }

  /// Delta chênh lệch giữa tổng tính toán và tổng hóa đơn
  int get deltaTotal {
    return computedTotal - bill.total;
  }

  /// Danh sách các món chưa được gán cho bất kỳ thành viên nào
  List<BillItemEntity> get unassignedItems {
    return bill.items.where((i) => i.assignments.isEmpty).toList();
  }
}

class BillDetailNotifier extends StateNotifier<BillDetailState> {
  final BillRepository _repository;

  BillDetailNotifier(this._repository, BillDetailEntity initialBill)
    : super(BillDetailState(bill: initialBill)) {
    final splitMethod = initialBill.splitMethod.isNotEmpty
        ? initialBill.splitMethod
        : 'item_ratio';
    final isEven = splitMethod == 'even';
    final effectiveItems = initialBill.items.map((item) {
      if (isEven && item.assignments.isEmpty) {
        return item.copyWith(
          assignments: _buildEvenAssignments(initialBill.members),
        );
      }
      return item;
    }).toList();

    final syncedBill = _syncBillWithItems(
      initialBill.copyWith(splitMethod: splitMethod),
      effectiveItems,
    );
    final effectiveMembers = initialBill.members;

    state = state.copyWith(
      bill: syncedBill,
      breakdown: _enrichBreakdown(
        initialBill.breakdown,
        effectiveMembers,
        initialBill.creditorMemberId,
      ),
    );
  }

  static List<BillShareBreakdownEntity> _enrichBreakdown(
    List<BillShareBreakdownEntity> list,
    List<BillMemberEntity> members,
    String creditorMemberId,
  ) {
    if (list.isEmpty) return list;
    return list.map((item) {
      final member = members.firstWhere(
        (m) => m.memberId == item.memberId,
        orElse: () => BillMemberEntity(
          memberId: item.memberId,
          userId: item.userId,
          displayName: item.displayName,
          avatarUrl: item.avatarUrl,
        ),
      );
      final isCreditor = item.memberId == creditorMemberId;
      return item.copyWith(
        userId: member.userId.isNotEmpty ? member.userId : item.userId,
        displayName:
            member.displayName.isNotEmpty && member.displayName != 'Thành viên'
            ? member.displayName
            : item.displayName,
        avatarUrl: member.avatarUrl ?? item.avatarUrl,
        isCreditor: isCreditor,
      );
    }).toList();
  }

  static List<BillItemAssignmentEntity> _buildEvenAssignments(
    List<BillMemberEntity> members,
  ) {
    if (members.isEmpty) return const [];
    final count = members.length;
    return members.map((m) {
      return BillItemAssignmentEntity(
        memberId: m.memberId,
        userId: m.userId,
        displayName: m.displayName,
        avatarUrl: m.avatarUrl,
        weight: 1.0 / count,
      );
    }).toList();
  }

  static List<BillItemEntity> _buildEvenItems(
    List<BillItemEntity> items,
    List<BillMemberEntity> members,
  ) {
    final evenAssignments = _buildEvenAssignments(members);
    return items.map((item) {
      return item.copyWith(
        assignments: List<BillItemAssignmentEntity>.from(evenAssignments),
      );
    }).toList();
  }

  static BillDetailEntity _syncBillWithItems(
    BillDetailEntity currentBill,
    List<BillItemEntity> items, {
    int? serviceCharge,
    int? vat,
    int? generalDiscount,
    int? total,
  }) {
    final sCharge = serviceCharge ?? currentBill.serviceCharge;
    final v = vat ?? currentBill.vat;
    final gDiscount = generalDiscount ?? currentBill.generalDiscount;

    final grossSubtotal = items.fold(0, (sum, i) => sum + i.lineTotal);
    final totalItemDiscount = items.fold(0, (sum, i) => sum + i.discountAmount);

    return currentBill.copyWith(
      items: items,
      subtotal: grossSubtotal,
      totalItemDiscount: totalItemDiscount,
      serviceCharge: sCharge,
      vat: v,
      generalDiscount: gDiscount,
      total: total ?? currentBill.total,
    );
  }

  void setCurrentUserId(String userId) {
    state = state.copyWith(currentUserId: userId);
  }

  /// Tải dữ liệu hoá đơn và danh sách thành viên nhóm từ API
  Future<void>? _loadInFlight;

  int get resourceVersion => state.bill.version;

  Future<void> loadBillDetail({
    required String billId,
    required String groupId,
    bool background = false,
  }) {
    return _loadInFlight ??= _loadBillDetail(
      billId: billId,
      groupId: groupId,
      background: background,
    ).whenComplete(() => _loadInFlight = null);
  }

  Future<void> _loadBillDetail({
    required String billId,
    required String groupId,
    required bool background,
  }) async {
    final previousBill = state.bill;
    state = state.copyWith(isLoading: !background, isRefreshing: background);
    try {
      // 1. Tải danh sách thành viên nhóm
      final membersResult = await _repository.getGroupMembers(groupId: groupId);
      if (!mounted) return;
      List<BillMemberEntity> members = [];
      membersResult.match((failure) => null, (mList) => members = mList);

      // 2. Nếu là hoá đơn mới chưa lưu trên DB (billId rỗng hoặc bắt đầu bằng draft-):
      // Chỉ cập nhật danh sách thành viên nhóm để gán người ăn, KHÔNG gọi GET bill lên server
      if (billId.isEmpty || billId.startsWith('draft-')) {
        final effectiveMembers = members.isNotEmpty
            ? members
            : state.bill.members;
        final splitMethod = state.bill.splitMethod.isNotEmpty
            ? state.bill.splitMethod
            : 'item_ratio';
        final isEven = splitMethod == 'even';

        // Tự động gán Chủ chi (Creditor) là user hiện tại hoặc Captain nhóm
        String creditorId = state.bill.creditorMemberId;
        String creditorName = state.bill.creditorName;

        final currentMember = effectiveMembers
            .cast<BillMemberEntity?>()
            .firstWhere(
              (m) =>
                  m?.userId.isNotEmpty == true &&
                  m?.userId == state.currentUserId,
              orElse: () => null,
            );
        final captainMember = effectiveMembers
            .cast<BillMemberEntity?>()
            .firstWhere((m) => m?.role == 'captain', orElse: () => null);

        final selectedCreditor =
            currentMember ??
            captainMember ??
            (effectiveMembers.isNotEmpty ? effectiveMembers.first : null);
        if (selectedCreditor != null &&
            (creditorId.isEmpty ||
                !effectiveMembers.any((m) => m.memberId == creditorId))) {
          creditorId = selectedCreditor.memberId;
          creditorName = selectedCreditor.displayName;
        }

        final processedItems = state.bill.items.map((item) {
          if (isEven && item.assignments.isEmpty) {
            return item.copyWith(
              assignments: _buildEvenAssignments(effectiveMembers),
            );
          }
          return item;
        }).toList();

        final syncedBill = _syncBillWithItems(
          state.bill.copyWith(
            members: effectiveMembers,
            creditorMemberId: creditorId,
            creditorName: creditorName,
            splitMethod: splitMethod,
          ),
          processedItems,
        );

        state = state.copyWith(
          bill: syncedBill,
          isLoading: false,
          isDirty: state.bill.items.isNotEmpty,
        );
        return;
      }

      // 3. Tải chi tiết hoá đơn đã lưu từ server (khi billId là UUID thực tế)
      final billResult = await _repository.getBillDetail(
        billId: billId,
        groupId: groupId,
      );
      if (!mounted) return;
      billResult.match(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        },
        (bill) {
          // A background response must not overwrite edits or a newer save.
          if (background &&
              (state.isDirty || !identical(state.bill, previousBill))) {
            return;
          }
          final effectiveMembers = members.isNotEmpty ? members : bill.members;
          final splitMethod = bill.splitMethod.isNotEmpty
              ? bill.splitMethod
              : 'item_ratio';
          final isEven = splitMethod == 'even';

          final processedItems = bill.items.map((item) {
            if (isEven && item.assignments.isEmpty) {
              return item.copyWith(
                assignments: _buildEvenAssignments(effectiveMembers),
              );
            }
            return item;
          }).toList();

          String creditorName = bill.creditorName;
          if (creditorName.isEmpty || creditorName == 'Chủ hoá đơn') {
            final matchedCreditor = effectiveMembers
                .cast<BillMemberEntity?>()
                .firstWhere(
                  (m) =>
                      m?.memberId == bill.creditorMemberId ||
                      (state.currentUserId != null &&
                          m?.userId == state.currentUserId),
                  orElse: () =>
                      effectiveMembers.cast<BillMemberEntity?>().firstWhere(
                        (m) => m?.role == 'captain',
                        orElse: () => effectiveMembers.isNotEmpty
                            ? effectiveMembers.first
                            : null,
                      ),
                );
            if (matchedCreditor != null) {
              creditorName = matchedCreditor.displayName;
            }
          }

          final syncedBill = _syncBillWithItems(
            bill.copyWith(
              members: effectiveMembers,
              creditorName: creditorName,
              splitMethod: splitMethod,
            ),
            processedItems,
          );

          state = state.copyWith(
            bill: syncedBill,
            breakdown: _enrichBreakdown(
              bill.breakdown,
              effectiveMembers,
              syncedBill.creditorMemberId,
            ),
            isLoading: false,
            isDirty: false,
          );
        },
      );
    } finally {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: state.errorMessage,
          successMessage: state.successMessage,
        );
      }
    }
  }

  /// Kích hoạt tiến trình tải ảnh & gọi AI OCR
  Future<void> runOcrProcess({
    required String groupId,
    required List<CapturedBillPhoto> photos,
    String? merchantName,
  }) async {
    if (state.isProcessing || photos.isEmpty) return;

    state = state.copyWith(
      isOcrScanning: true,
      ocrScanStep: 'Đang tải ảnh lên...',
      clearOcrCandidate: true,
    );

    // 1. Tải trước danh sách thành viên nhóm nếu chưa có
    if (state.bill.members.isEmpty) {
      final membersResult = await _repository.getGroupMembers(groupId: groupId);
      if (!mounted) return;
      membersResult.match((failure) => null, (mList) {
        state = state.copyWith(bill: state.bill.copyWith(members: mList));
      });
    }

    state = state.copyWith(
      ocrScanStep: 'AI Llama đang bóc tách món ăn & số tiền...',
    );

    final result = await _repository.createBillWithPhotos(
      groupId: groupId,
      merchantName:
          merchantName ?? state.bill.merchantName ?? 'Hoá đơn chi tiêu',
      photos: photos,
    );
    if (!mounted) return;

    result.match(
      (failure) {
        state = state.copyWith(
          isOcrScanning: false,
          clearOcrScanStep: true,
          ocrErrorMessage: failure.message,
        );
      },
      (candidateBill) {
        final enrichedCandidate = candidateBill.copyWith(
          members: candidateBill.members.isNotEmpty
              ? candidateBill.members
              : state.bill.members,
          photos: photos,
        );

        // OCR hỏng hoặc chưa xong vẫn trả về một hóa đơn hợp lệ — chỉ là không
        // có món nào. Đưa thẳng nó vào `ocrCandidate` thì màn hình dựng nhánh
        // "bóc tách thành công" với tổng 0đ, và người dùng không hề biết là
        // AI đã thất bại. Giữ lại bill (id của nó là thứ để thử lại) nhưng báo
        // đúng bản chất.
        final ocrFailure = _ocrFailureMessage(candidateBill);
        if (ocrFailure != null) {
          state = state.copyWith(
            bill: state.bill.copyWith(
              id: candidateBill.id.isNotEmpty
                  ? candidateBill.id
                  : state.bill.id,
              version: candidateBill.version,
              members: enrichedCandidate.members,
              photos: photos,
              ocrStatus: candidateBill.ocrStatus,
              ocrErrorCode: candidateBill.ocrErrorCode,
            ),
            isOcrScanning: false,
            clearOcrScanStep: true,
            clearOcrCandidate: true,
            ocrErrorMessage: ocrFailure,
          );
          return;
        }

        state = state.copyWith(
          isOcrScanning: false,
          clearOcrScanStep: true,
          ocrCandidate: enrichedCandidate,
        );
      },
    );
  }

  /// Đưa lỗi OCR của hóa đơn vừa tải lên bề mặt, trả về `true` khi có lỗi cần báo.
  ///
  /// Người tạo hóa đơn rời màn hình trước khi AI trả kết quả sẽ chỉ gặp lại nó
  /// qua danh sách hóa đơn của nhóm. Không có bước này thì hóa đơn đó mở ra là
  /// một bản nháp trống trơn, không dấu vết nào cho thấy OCR đã hỏng.
  bool surfaceLoadedOcrFailure() {
    if (state.bill.ocrStatus != OcrJobStatus.failed) return false;
    // Đã có món (nhập tay, hoặc lần bóc tách trước đó đã apply) thì lỗi cũ
    // không còn là chuyện đang cản trở ai.
    if (state.bill.items.isNotEmpty) return false;

    final message = _ocrFailureMessage(state.bill);
    if (message == null) return false;
    state = state.copyWith(ocrErrorMessage: message);
    return true;
  }

  /// Chạy lại OCR trên hóa đơn đã lưu, thay vì tạo thêm một hóa đơn nữa.
  ///
  /// Bấm "Thử lại" mà gọi lại [runOcrProcess] thì mỗi lần thử đẻ ra một bill
  /// draft mới trong nhóm; và với hóa đơn mở lại từ danh sách thì trong tay
  /// không còn bytes ảnh nên [runOcrProcess] im lặng không làm gì cả.
  Future<void> retryOcr({
    required String groupId,
    required String billId,
  }) async {
    if (state.isProcessing || billId.isEmpty) return;

    state = state.copyWith(
      isOcrScanning: true,
      ocrScanStep: 'Đang chạy lại bóc tách AI...',
      clearOcrCandidate: true,
    );

    final result = await _repository.retryOcr(
      billId: billId,
      groupId: groupId,
      photos: state.bill.photos,
    );
    if (!mounted) return;

    result.match(
      (failure) {
        state = state.copyWith(
          isOcrScanning: false,
          clearOcrScanStep: true,
          ocrErrorMessage: failure.message,
        );
      },
      (rescanned) {
        final enriched = rescanned.copyWith(
          members: rescanned.members.isNotEmpty
              ? rescanned.members
              : state.bill.members,
          photos: rescanned.photos.isNotEmpty
              ? rescanned.photos
              : state.bill.photos,
        );

        final ocrFailure = _ocrFailureMessage(rescanned);
        if (ocrFailure != null) {
          state = state.copyWith(
            bill: state.bill.copyWith(
              version: rescanned.version,
              members: enriched.members,
              ocrStatus: rescanned.ocrStatus,
              ocrErrorCode: rescanned.ocrErrorCode,
            ),
            isOcrScanning: false,
            clearOcrScanStep: true,
            clearOcrCandidate: true,
            ocrErrorMessage: ocrFailure,
          );
          return;
        }

        state = state.copyWith(
          isOcrScanning: false,
          clearOcrScanStep: true,
          ocrCandidate: enriched,
        );
      },
    );
  }

  /// Câu thông báo khi lần bóc tách này không cho ra kết quả dùng được, hoặc
  /// `null` khi OCR thực sự thành công.
  ///
  /// Một job `succeeded` mà đọc được 0 món không phải lỗi: ảnh mờ hay hóa đơn
  /// viết tay vẫn là kết quả hợp lệ, và màn hình xem trước đã có sẵn câu
  /// "Không tìm thấy dòng món nào trong ảnh" cho trường hợp đó.
  String? _ocrFailureMessage(BillDetailEntity bill) {
    switch (bill.ocrStatus) {
      case OcrJobStatus.succeeded:
      case OcrJobStatus.none:
        return null;
      case OcrJobStatus.queued:
      case OcrJobStatus.processing:
        return 'AI vẫn đang bóc tách hóa đơn này và chưa trả kết quả. '
            'Bạn có thể thử lại sau ít phút hoặc tự nhập tay.';
      case OcrJobStatus.failed:
        return switch (bill.ocrErrorCode) {
          'provider_timeout' =>
            'AI xử lý ảnh quá lâu và đã hết thời gian chờ. Hãy thử lại, hoặc '
                'chụp lại ảnh rõ nét hơn.',
          'provider_unavailable' =>
            'Dịch vụ bóc tách AI đang không khả dụng. Hãy thử lại sau ít phút.',
          'schema_invalid' =>
            'AI không đọc được cấu trúc hóa đơn trong ảnh này. Hãy chụp lại '
                'sao cho thấy rõ toàn bộ hóa đơn, hoặc tự nhập tay.',
          'download_failed' =>
            'Không tải được ảnh hóa đơn đã lưu. Hãy thử lại.',
          'no_images' => 'Hóa đơn này không có ảnh nào để bóc tách.',
          // Mã do reaper của backend ghi: tiến trình bóc tách đứng yên quá lâu
          // và đã bị dọn để hóa đơn này chạy lại được.
          'stale_timeout' =>
            'Lần bóc tách trước bị gián đoạn và đã dừng hẳn. Hãy thử lại.',
          _ =>
            'Bóc tách hóa đơn bằng AI thất bại. Hãy thử lại, hoặc tự nhập tay.',
        };
    }
  }

  /// Áp dụng kết quả OCR vào hoá đơn chính và tự động lưu bản nháp xuống DB
  Future<void> applyOcrCandidate() async {
    if (state.ocrCandidate == null) return;
    final candidate = state.ocrCandidate!;
    final effectiveMembers = candidate.members.isNotEmpty
        ? candidate.members
        : state.bill.members;

    final candidateItems = candidate.items.asMap().entries.map((entry) {
      final idx = entry.key;
      final it = entry.value;
      final effectiveId = it.id.isNotEmpty
          ? it.id
          : 'ocr-item-${DateTime.now().microsecondsSinceEpoch}-$idx';
      return it.copyWith(id: effectiveId, position: idx);
    }).toList();

    final evenItems = _buildEvenItems(candidateItems, effectiveMembers);

    String creditorId = candidate.creditorMemberId.isNotEmpty
        ? candidate.creditorMemberId
        : state.bill.creditorMemberId;
    String creditorName = candidate.creditorName;

    if (creditorName.isEmpty || creditorName == 'Chủ hoá đơn') {
      final matchedCreditor = effectiveMembers
          .cast<BillMemberEntity?>()
          .firstWhere(
            (m) =>
                m?.memberId == creditorId ||
                (state.currentUserId != null &&
                    m?.userId == state.currentUserId),
            orElse: () => effectiveMembers.cast<BillMemberEntity?>().firstWhere(
              (m) => m?.role == 'captain',
              orElse: () =>
                  effectiveMembers.isNotEmpty ? effectiveMembers.first : null,
            ),
          );
      if (matchedCreditor != null) {
        creditorId = matchedCreditor.memberId;
        creditorName = matchedCreditor.displayName;
      }
    }

    final updatedBill = _syncBillWithItems(
      state.bill.copyWith(
        id: candidate.id.isNotEmpty ? candidate.id : state.bill.id,
        creditorMemberId: creditorId,
        creditorName: creditorName,
        merchantName: candidate.merchantName?.isNotEmpty == true
            ? candidate.merchantName
            : state.bill.merchantName,
        billDate: candidate.billDate ?? state.bill.billDate,
        createdAt: candidate.createdAt ?? state.bill.createdAt,
        serviceCharge: candidate.serviceCharge,
        vat: candidate.vat,
        generalDiscount: candidate.generalDiscount,
        members: effectiveMembers,
        splitMethod: 'even',
        version: candidate.version,
      ),
      evenItems,
      total: candidate.total,
    );

    state = state.copyWith(
      bill: updatedBill,
      clearOcrCandidate: true,
      isSaving: true,
    );

    await _executeSaveDraft(silent: true);
  }

  /// Bỏ qua / Huỷ OCR candidate (người dùng chọn tự nhập tay)
  void dismissOcrCandidate() {
    state = state.copyWith(clearOcrCandidate: true, isOcrScanning: false);
  }

  /// Đổi chế độ chia tiền: Theo món (`item_ratio`) vs Chia đều (`even`)
  void setSplitMode(String mode) {
    if (state.bill.splitMethod == mode) return;

    if (mode == 'even') {
      // Chuyển sang Chia đều: gán các thành viên tham gia chia đều vào tất cả các món
      final targetMemberIds = state.activeEvenSplitMemberIds;
      final selectedMembers = state.bill.members
          .where((m) => targetMemberIds.contains(m.memberId))
          .toList();
      final evenItems = _buildEvenItems(
        state.bill.items,
        selectedMembers.isNotEmpty ? selectedMembers : state.bill.members,
      );
      final updatedBill = _syncBillWithItems(
        state.bill.copyWith(splitMethod: 'even'),
        evenItems,
      );
      state = state.copyWith(bill: updatedBill, isDirty: true);
    } else {
      // Chuyển sang Chia theo món: GIỮ NGUYÊN bộ data phân bổ món ăn hiện tại (không xoá)
      final updatedBill = _syncBillWithItems(
        state.bill.copyWith(splitMethod: 'item_ratio'),
        state.bill.items,
      );
      state = state.copyWith(bill: updatedBill, isDirty: true);
    }
  }

  /// Cập nhật danh sách thành viên tham gia chia đều
  void setEvenSplitMembers(Set<String> memberIds) {
    if (memberIds.isEmpty) return;
    final selectedMembers = state.bill.members
        .where((m) => memberIds.contains(m.memberId))
        .toList();
    final evenItems = _buildEvenItems(state.bill.items, selectedMembers);
    final updatedBill = _syncBillWithItems(
      state.bill.copyWith(splitMethod: 'even'),
      evenItems,
    );
    state = state.copyWith(
      bill: updatedBill,
      evenSplitMemberIds: memberIds,
      isDirty: true,
    );
  }

  /// Bật/Tắt gán một thành viên vào một món ăn cụ thể (chế độ chia theo món)
  void toggleMemberAssignment(String itemId, String memberId) {
    final member = state.bill.members.firstWhere(
      (m) => m.memberId == memberId,
      orElse: () => BillMemberEntity(
        memberId: memberId,
        userId: '',
        displayName: 'Thành viên',
      ),
    );

    final updatedItems = state.bill.items.map((item) {
      if (item.id != itemId) return item;

      final existingAssignments = List<BillItemAssignmentEntity>.from(
        item.assignments,
      );
      final index = existingAssignments.indexWhere(
        (a) => a.memberId == memberId,
      );

      if (index >= 0) {
        existingAssignments.removeAt(index);
      } else {
        existingAssignments.add(
          BillItemAssignmentEntity(
            memberId: memberId,
            userId: member.userId,
            displayName: member.displayName,
            avatarUrl: member.avatarUrl,
          ),
        );
      }

      final count = existingAssignments.length;
      final reweighted = existingAssignments.map((a) {
        return a.copyWith(weight: count > 0 ? (1.0 / count) : 1.0);
      }).toList();

      return item.copyWith(assignments: reweighted);
    }).toList();

    final updatedBill = _syncBillWithItems(state.bill, updatedItems);

    state = state.copyWith(bill: updatedBill, isDirty: true);
  }

  /// Gán tất cả thành viên trong nhóm vào món này (chế độ chia theo món)
  void assignAllMembersToItem(String itemId) {
    final allMembers = state.bill.members;
    final evenAssignments = _buildEvenAssignments(allMembers);

    final updatedItems = state.bill.items.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(
        assignments: List<BillItemAssignmentEntity>.from(evenAssignments),
      );
    }).toList();

    final updatedBill = _syncBillWithItems(state.bill, updatedItems);

    state = state.copyWith(bill: updatedBill, isDirty: true);
  }

  /// Cập nhật thông tin món ăn (tên, số lượng, đơn giá, chiết khấu riêng)
  void updateItem(BillItemEntity item) {
    final isEven = state.bill.splitMethod == 'even';
    final effectiveItem = isEven
        ? item.copyWith(assignments: _buildEvenAssignments(state.bill.members))
        : item;

    final updatedItems = state.bill.items.map((i) {
      if (i.id != item.id) return i;
      return effectiveItem;
    }).toList();

    final updatedBill = _syncBillWithItems(state.bill, updatedItems);

    state = state.copyWith(bill: updatedBill, isDirty: true);
  }

  /// Thêm món mới vào hoá đơn
  void addItem(BillItemEntity newItem) {
    final isEven = state.bill.splitMethod == 'even';
    final effectiveItem = isEven
        ? newItem.copyWith(
            assignments: _buildEvenAssignments(state.bill.members),
          )
        : newItem;

    final updatedItems = [...state.bill.items, effectiveItem];
    final updatedBill = _syncBillWithItems(state.bill, updatedItems);

    state = state.copyWith(bill: updatedBill, isDirty: true);
  }

  /// Xoá món khỏi hoá đơn
  void deleteItem(String itemId) {
    final updatedItems = state.bill.items.where((i) => i.id != itemId).toList();
    final updatedBill = _syncBillWithItems(state.bill, updatedItems);

    state = state.copyWith(bill: updatedBill, isDirty: true);
  }

  /// Cập nhật Thuế, Phí và Khuyến mãi chung.
  ///
  /// Tổng thanh toán luôn được suy ra từ các giá trị này, người dùng không nhập
  /// tổng bằng tay trong modal adjustments.
  void setAdjustments({int? serviceCharge, int? vat, int? generalDiscount}) {
    final safeServiceCharge = (serviceCharge ?? state.bill.serviceCharge)
        .clamp(0, 99999999999)
        .toInt();
    final safeVat = (vat ?? state.bill.vat).clamp(0, 99999999999).toInt();
    final maxDiscount =
        state.computedNetItemsTotal + safeServiceCharge + safeVat;
    final safeGeneralDiscount = (generalDiscount ?? state.bill.generalDiscount)
        .clamp(0, maxDiscount)
        .toInt();

    final updatedBill = _syncBillWithItems(
      state.bill,
      state.bill.items,
      serviceCharge: safeServiceCharge,
      vat: safeVat,
      generalDiscount: safeGeneralDiscount,
    );

    state = state.copyWith(bill: updatedBill, isDirty: true);
  }

  /// Cập nhật tên quán / địa điểm
  void setMerchantName(String name) {
    if (state.bill.merchantName == name) return;
    state = state.copyWith(
      bill: state.bill.copyWith(merchantName: name),
      isDirty: true,
    );
  }

  /// Cân bằng tổng hoá đơn: Đặt `total` thành `computedTotal`
  void balanceTotalToComputed() {
    state = state.copyWith(
      bill: state.bill.copyWith(total: state.computedTotal),
      isDirty: true,
    );
  }

  /// Cộng phần thiếu vào phụ thu để giữ đúng cơ chế phân bổ theo tỷ trọng.
  void addMissingAmountToServiceCharge(int amount) {
    if (amount <= 0) return;
    setAdjustments(serviceCharge: state.bill.serviceCharge + amount);
  }

  /// Cộng phần dư vào voucher chung để tổng tự tính khớp hóa đơn gốc.
  void addExcessAmountToVoucher(int amount) {
    if (amount <= 0) return;
    setAdjustments(generalDiscount: state.bill.generalDiscount + amount);
  }

  /// Thực thi lưu bản nháp lên server (hàm nội bộ dùng chung)
  Future<bool> _executeSaveDraft({
    bool isParentFinalizing = false,
    bool silent = false,
  }) async {
    final isNewBill =
        state.bill.id.isEmpty || state.bill.id.startsWith('draft-');

    if (isNewBill) {
      final result = await _repository.createManualBill(
        groupId: state.bill.groupId,
        merchantName: state.bill.merchantName ?? 'Hoá đơn chi tiêu',
        total: state.bill.total,
        items: state.bill.items,
        // Gửi đủ như khi lưu nháp: thiếu thuế phí và split_method thì bản ghi
        // đầu tiên trên server đã sai ngay từ lúc tạo.
        subtotal: state.computedGrossSubtotal,
        serviceCharge: state.bill.serviceCharge,
        vat: state.bill.vat,
        discount: state.computedTotalItemDiscount + state.bill.generalDiscount,
        splitMethod: state.bill.splitMethod.isEmpty
            ? 'item_ratio'
            : state.bill.splitMethod,
        billDate: state.bill.billDate,
      );
      if (!mounted) return false;

      return result.match(
        (failure) {
          state = state.copyWith(
            isSaving: false,
            isFinalizing: isParentFinalizing ? false : null,
            errorMessage: 'Tạo hoá đơn thất bại: ${failure.message}',
          );
          return false;
        },
        (createdBill) {
          final syncedBill = _syncBillWithItems(
            createdBill.copyWith(
              members: state.bill.members,
              photos: state.bill.photos,
            ),
            createdBill.items,
          );
          state = state.copyWith(
            bill: syncedBill,
            breakdown: _enrichBreakdown(
              createdBill.breakdown,
              state.bill.members,
              syncedBill.creditorMemberId,
            ),
            isSaving: false,
            isDirty: false,
            successMessage: (isParentFinalizing || silent)
                ? null
                : 'Đã lưu bản nháp',
          );
          return true;
        },
      );
    }

    final payload = {
      'merchant_name': state.bill.merchantName,
      // Không gửi bill_date thì backend ghi NULL mỗi lần lưu, ngày trên hóa đơn
      // bị thay bằng "hôm nay" ở lần mở lại.
      if (state.bill.billDate != null)
        'bill_date': state.bill.billDate!.toUtc().toIso8601String(),
      'subtotal': state.computedGrossSubtotal,
      'service_charge': state.bill.serviceCharge,
      'vat': state.bill.vat,
      'discount': state.computedTotalItemDiscount + state.bill.generalDiscount,
      'total': state.bill.total,
      'split_method': state.bill.splitMethod,
      'version': state.bill.version,
      'items': state.bill.items.map((i) => i.toJson()).toList(),
    };

    final result = await _repository.updateDraftBill(
      billId: state.bill.id,
      groupId: state.bill.groupId,
      payload: payload,
    );
    if (!mounted) return false;

    return result.match(
      (failure) {
        state = state.copyWith(
          isSaving: false,
          isFinalizing: isParentFinalizing ? false : null,
          errorMessage: 'Lưu nháp thất bại: ${failure.message}',
        );
        return false;
      },
      (updatedBill) {
        final existingItems = state.bill.items;
        final resolvedItems = updatedBill.items.isNotEmpty
            ? updatedBill.items
            : existingItems;
        final syncedBill = _syncBillWithItems(
          updatedBill.copyWith(
            items: resolvedItems,
            members: state.bill.members,
            photos: state.bill.photos,
          ),
          resolvedItems,
        );
        state = state.copyWith(
          bill: syncedBill,
          breakdown: _enrichBreakdown(
            updatedBill.breakdown.isNotEmpty
                ? updatedBill.breakdown
                : state.breakdown,
            state.bill.members,
            syncedBill.creditorMemberId,
          ),
          isSaving: false,
          isDirty: false,
          successMessage: (isParentFinalizing || silent)
              ? null
              : 'Đã lưu bản nháp',
        );
        return true;
      },
    );
  }

  /// Lưu bản nháp lên server và nhận kết quả phân bổ chính thức từ Backend
  Future<bool> saveDraft() async {
    if (state.isProcessing) return false;
    state = state.copyWith(isSaving: true);
    return _executeSaveDraft();
  }

  /// Gọi API Backend (POST /bills/calculate hoặc POST /bills/{id}/calculate) để BE tính và trả về kết quả phân bổ
  Future<List<BillShareBreakdownEntity>?> calculateBreakdown() async {
    if (state.isProcessing) return null;
    state = state.copyWith(isCalculatingBreakdown: true);

    final payload = {
      'group_id': state.bill.groupId,
      'merchant_name': state.bill.merchantName,
      'subtotal': state.computedGrossSubtotal,
      'service_charge': state.bill.serviceCharge,
      'vat': state.bill.vat,
      'discount': state.computedTotalItemDiscount + state.bill.generalDiscount,
      'total': state.bill.total,
      'split_method': state.bill.splitMethod,
      'creditor_member_id': state.bill.creditorMemberId,
      'items': state.bill.items.map((i) => i.toJson()).toList(),
    };

    final result = await _repository.calculateBreakdown(
      billId: state.bill.id.isNotEmpty ? state.bill.id : null,
      groupId: state.bill.groupId,
      payload: payload,
    );
    if (!mounted) return null;

    return result.match(
      (failure) {
        state = state.copyWith(
          isCalculatingBreakdown: false,
          errorMessage: 'Tính toán phân bổ thất bại: ${failure.message}',
        );
        return null;
      },
      (breakdownList) {
        final enrichedList = _enrichBreakdown(
          breakdownList,
          state.bill.members,
          state.bill.creditorMemberId,
        );
        state = state.copyWith(
          breakdown: enrichedList,
          isCalculatingBreakdown: false,
        );
        return enrichedList;
      },
    );
  }

  /// Tải bảng phân bổ chính thức từ Backend khi người dùng bấm nút Phân bổ.
  /// Đối với hoá đơn đã chốt (finalized/voided), dữ liệu snapshot phân bổ đã có sẵn từ DB nên trả về ngay lập tức.
  Future<List<BillShareBreakdownEntity>> fetchOfficialBreakdown() async {
    final isReadOnly =
        state.bill.status == 'finalized' || state.bill.status == 'voided';
    if (isReadOnly &&
        (state.breakdown.isNotEmpty || state.bill.breakdown.isNotEmpty)) {
      return state.breakdown.isNotEmpty
          ? state.breakdown
          : state.bill.breakdown;
    }
    final breakdown = await calculateBreakdown();
    if (!mounted) return breakdown ?? const [];
    return breakdown ?? state.breakdown;
  }

  /// Chuyển [Failure] thành thông báo tiếng Việt dựa trên `failure.code` ổn
  /// định do backend trả về, thay vì khớp theo câu chữ của message.
  String _friendlyBillError(Failure failure) {
    switch (failure.code) {
      case 'ITEM_UNASSIGNED':
        return 'Có món ăn chưa được gán cho thành viên nào. Vui lòng chọn người ăn cho tất cả các món.';
      case 'CREDITOR_REQUIRED':
        return 'Vui lòng chọn Người thanh toán (Chủ chi) trước khi chốt hoá đơn.';
      case 'SUBTOTAL_MISMATCH':
        return 'Tổng tiền các món không khớp với tiền hàng tạm tính.';
      case 'TOTAL_MISMATCH':
        return 'Tổng thanh toán không khớp với công thức tiền món + phí/thuế - giảm giá.';
      case 'DISCOUNT_EXCEEDS_BILL':
        return 'Tiền giảm giá vượt quá tổng giá trị hoá đơn.';
      case 'INACTIVE_MEMBER_ASSIGNED':
        return 'Có thành viên đã rời nhóm trong danh sách chia tiền.';
      case 'BILL_ALREADY_VOIDED':
        return 'Hoá đơn này đã bị huỷ trước đó.';
      case 'PAYMENT_ALREADY_STARTED':
        return 'Không thể huỷ vì đã có thành viên bắt đầu thanh toán cho hoá đơn này.';
      case 'CAPTAIN_REQUIRED':
        return 'Chỉ Trưởng nhóm mới có quyền huỷ hoá đơn đã chốt.';
      case 'BILL_IMMUTABLE':
        return 'Hoá đơn đã rời trạng thái nháp nên không xóa được nữa. Dùng "Huỷ hoá đơn" nếu cần gỡ bỏ.';
      case 'FORBIDDEN':
        return 'Chỉ Trưởng nhóm hoặc người tạo hoá đơn mới được thao tác này.';
      case 'BILL_NOT_FOUND':
        return 'Hoá đơn không còn tồn tại, có thể đã bị xóa trước đó.';
      case 'VERSION_CONFLICT':
        return 'Dữ liệu hoá đơn đã bị thay đổi, vui lòng tải lại trang.';
      case 'GROUP_ARCHIVED':
        return 'Nhóm này đã bị giải tán.';
      default:
        return failure.message;
    }
  }

  /// Thực hiện riêng bước Đối soát (Review Bill) chuyển status từ draft -> reviewed
  Future<bool> reviewBillOnly() async {
    if (state.isProcessing) return false;
    state = state.copyWith(isSaving: true);

    // 1. Chỉ lưu nháp nếu có thay đổi hoặc là hoá đơn mới tạo
    final isNewBill =
        state.bill.id.isEmpty || state.bill.id.startsWith('draft-');
    if (state.isDirty || isNewBill) {
      final saved = await _executeSaveDraft();
      if (!mounted) return false;
      if (!saved) {
        state = state.copyWith(isSaving: false);
        return false;
      }
    }

    // 2. Bước Đối soát (Review Bill)
    final reviewResult = await _repository.reviewBill(
      billId: state.bill.id,
      groupId: state.bill.groupId,
      version: state.bill.version,
    );
    if (!mounted) return false;

    return reviewResult.match(
      (failure) {
        state = state.copyWith(
          isSaving: false,
          errorMessage:
              'Đối soát hoá đơn không đạt: ${_friendlyBillError(failure)}',
        );
        return false;
      },
      (bill) {
        final existingItems = state.bill.items;
        final resolvedItems = bill.items.isNotEmpty
            ? bill.items
            : existingItems;
        state = state.copyWith(
          isSaving: false,
          bill: _syncBillWithItems(
            bill.copyWith(
              items: resolvedItems,
              members: state.bill.members,
              photos: state.bill.photos,
            ),
            resolvedItems,
          ),
          breakdown: _enrichBreakdown(
            bill.breakdown.isNotEmpty ? bill.breakdown : state.breakdown,
            state.bill.members,
            state.bill.creditorMemberId,
          ),
          isDirty: false,
          successMessage: 'Đã gửi đối soát',
        );
        return true;
      },
    );
  }

  /// Chốt sổ hoá đơn (Tự động lưu nháp nếu sửa -> Đối soát nếu chưa -> Chốt sổ Finalize)
  Future<FinalizeBillResult> finalizeBill({String? idempotencyKey}) async {
    if (state.isProcessing) {
      return const FinalizeBillResult.failed('Đang xử lý');
    }
    state = state.copyWith(isFinalizing: true);

    // 1. Chỉ lưu nháp nếu có thay đổi hoặc là hoá đơn mới tạo
    final isNewBill =
        state.bill.id.isEmpty || state.bill.id.startsWith('draft-');
    if (state.isDirty || isNewBill) {
      final saved = await _executeSaveDraft(isParentFinalizing: true);
      if (!mounted) {
        return const FinalizeBillResult.failed('Màn hình đã đóng');
      }
      if (!saved) {
        state = state.copyWith(isFinalizing: false);
        return const FinalizeBillResult.failed('Không thể lưu bản nháp');
      }
    }

    int currentVersion = state.bill.version;

    // 2. Bước Đối soát (Review Bill): Chỉ gọi nếu hoá đơn chưa ở trạng thái reviewed
    if (state.bill.status != 'reviewed') {
      final reviewResult = await _repository.reviewBill(
        billId: state.bill.id,
        groupId: state.bill.groupId,
        version: state.bill.version,
      );
      if (!mounted) {
        return const FinalizeBillResult.failed('Màn hình đã đóng');
      }

      final reviewSuccess = reviewResult.match(
        (failure) {
          final isConflict = _isVersionConflict(failure);
          state = state.copyWith(
            isFinalizing: false,
            errorMessage: isConflict
                ? null
                : 'Đối soát hoá đơn không đạt: ${_friendlyBillError(failure)}',
          );
          return isConflict
              ? const FinalizeBillResult.versionConflict()
              : FinalizeBillResult.failed(failure.message);
        },
        (bill) {
          final existingItems = state.bill.items;
          final resolvedItems = bill.items.isNotEmpty
              ? bill.items
              : existingItems;
          state = state.copyWith(
            bill: _syncBillWithItems(
              bill.copyWith(
                items: resolvedItems,
                members: state.bill.members,
                photos: state.bill.photos,
              ),
              resolvedItems,
            ),
            breakdown: _enrichBreakdown(
              bill.breakdown.isNotEmpty ? bill.breakdown : state.breakdown,
              state.bill.members,
              state.bill.creditorMemberId,
            ),
            isDirty: false,
          );
          currentVersion = bill.version;
          return null;
        },
      );

      if (reviewSuccess != null) {
        return reviewSuccess;
      }
    }

    // 3. Bước Chốt sổ (Finalize Bill) chính thức ghi nợ cho nhóm (Spec 3 AC-9) kèm Idempotency-Key
    final effectiveIdempotencyKey =
        (idempotencyKey != null && idempotencyKey.isNotEmpty)
        ? idempotencyKey
        : const Uuid().v4();

    final finalizeResult = await _repository.finalizeBill(
      billId: state.bill.id,
      groupId: state.bill.groupId,
      version: currentVersion,
      idempotencyKey: effectiveIdempotencyKey,
    );
    // Chốt sổ đã ghi nợ xong trên server; màn hình đóng giữa chừng không làm
    // điều đó chưa xảy ra, nên vẫn báo thành công cho người gọi.
    if (!mounted) {
      return finalizeResult.match(
        (failure) => FinalizeBillResult.failed(failure.message),
        (_) => const FinalizeBillResult.success(),
      );
    }

    return finalizeResult.match(
      (failure) {
        final isConflict = _isVersionConflict(failure);
        state = state.copyWith(
          isFinalizing: false,
          errorMessage: isConflict
              ? null
              : 'Chốt hoá đơn thất bại: ${_friendlyBillError(failure)}',
        );
        if (isConflict) {
          return const FinalizeBillResult.versionConflict();
        }
        return FinalizeBillResult.failed(failure.message);
      },
      (_) {
        state = state.copyWith(
          isFinalizing: false,
          bill: state.bill.copyWith(status: 'finalized'),
          successMessage: 'Chốt hoá đơn thành công',
        );
        return const FinalizeBillResult.success();
      },
    );
  }

  bool _isVersionConflict(Failure failure) {
    if (failure.code == 'VERSION_CONFLICT' ||
        failure.code == 'VERSION_MISMATCH') {
      return true;
    }
    if (failure is ServerFailure && failure.statusCode == 409) {
      return failure.code == 'VERSION_CONFLICT' ||
          failure.code == 'VERSION_MISMATCH' ||
          failure.message.toLowerCase().contains('version') ||
          failure.message.toLowerCase().contains('cập nhật');
    }
    return false;
  }

  /// Tải lại chi tiết hoá đơn mới nhất từ server (dùng khi gặp xung đột phiên bản)
  Future<bool> reloadBill() async {
    if (state.bill.id.isEmpty) return false;
    state = state.copyWith(isLoading: true);
    final billResult = await _repository.getBillDetail(
      billId: state.bill.id,
      groupId: state.bill.groupId,
    );
    if (!mounted) return false;
    return billResult.match(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải lại hoá đơn: ${failure.message}',
        );
        return false;
      },
      (freshBill) {
        final effectiveMembers = freshBill.members.isNotEmpty
            ? freshBill.members
            : state.bill.members;
        final syncedBill = _syncBillWithItems(
          freshBill.copyWith(
            members: effectiveMembers,
            photos: freshBill.photos.isNotEmpty
                ? freshBill.photos
                : state.bill.photos,
          ),
          freshBill.items,
        );
        state = state.copyWith(
          isLoading: false,
          bill: syncedBill,
          breakdown: _enrichBreakdown(
            freshBill.breakdown,
            effectiveMembers,
            syncedBill.creditorMemberId,
          ),
          isDirty: false,
          successMessage: 'Đã tải dữ liệu mới nhất',
        );
        return true;
      },
    );
  }

  /// Xóa hẳn một hoá đơn còn nháp (kèm ảnh đã tải lên).
  ///
  /// Khác [voidBill]: huỷ chỉ dùng cho hoá đơn đã chốt và giữ lại bản ghi cùng
  /// lý do; xóa nháp là gỡ bỏ hẳn một hoá đơn chưa từng sinh công nợ.
  Future<bool> deleteDraftBill() async {
    if (state.isProcessing) return false;

    // Hoá đơn chưa từng lưu lên server thì không có gì để xóa: rời màn hình là
    // xong, gọi API chỉ tổ nhận 404.
    if (state.bill.id.isEmpty || state.bill.id.startsWith('draft-')) {
      return true;
    }

    state = state.copyWith(isDeleting: true);

    final result = await _repository.deleteDraftBill(
      billId: state.bill.id,
      groupId: state.bill.groupId,
    );
    // Xóa đã xảy ra thật trên server; màn hình đóng giữa chừng không hoàn tác
    // được nó, nên kết quả trả về người gọi vẫn theo phản hồi của server.
    if (!mounted) return result.isRight();

    return result.match(
      (failure) {
        state = state.copyWith(
          isDeleting: false,
          errorMessage: 'Xóa hoá đơn thất bại: ${_friendlyBillError(failure)}',
        );
        return false;
      },
      (_) {
        state = state.copyWith(isDeleting: false);
        return true;
      },
    );
  }

  /// Huỷ hoá đơn đã chốt (Chỉ Trưởng nhóm có quyền)
  Future<bool> voidBill({required String reason}) async {
    if (state.isProcessing) return false;

    if (reason.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập lý do huỷ hoá đơn.');
      return false;
    }

    state = state.copyWith(isVoiding: true);

    final result = await _repository.voidBill(
      billId: state.bill.id,
      groupId: state.bill.groupId,
      version: state.bill.version,
      reason: reason.trim(),
    );
    if (!mounted) return result.isRight();

    return result.match(
      (failure) {
        state = state.copyWith(
          isVoiding: false,
          errorMessage: 'Huỷ hoá đơn thất bại: ${_friendlyBillError(failure)}',
        );
        return false;
      },
      (voidedBill) {
        final existingItems = state.bill.items;
        final resolvedItems = voidedBill.items.isNotEmpty
            ? voidedBill.items
            : existingItems;
        final syncedBill = _syncBillWithItems(
          voidedBill.copyWith(
            status: 'voided',
            items: resolvedItems,
            members: state.bill.members,
            photos: state.bill.photos,
          ),
          resolvedItems,
        );

        state = state.copyWith(
          isVoiding: false,
          bill: syncedBill,
          breakdown: _enrichBreakdown(
            voidedBill.breakdown.isNotEmpty
                ? voidedBill.breakdown
                : state.breakdown,
            state.bill.members,
            syncedBill.creditorMemberId,
          ),
          successMessage: 'Đã huỷ hoá đơn',
        );
        return true;
      },
    );
  }
}

/// `autoDispose` có chủ đích: khóa của family là chính `BillDetailEntity` khởi
/// tạo, nên mỗi lần mở màn chi tiết — kể cả mỗi lần quét OCR, vì lần nào cũng
/// dựng một entity mới — là một entry mới trong family. Không có autoDispose thì
/// không entry nào bị gỡ: notifier sống tới hết phiên, và realtime interest
/// nó đăng ký cũng vậy, nên mỗi frame realtime lại kéo theo một lượt
/// `loadBillDetail` cho từng màn hình đã đóng từ lâu.
final billDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<BillDetailNotifier, BillDetailState, BillDetailEntity>((
      ref,
      initialBill,
    ) {
      ref.watch(sessionRevisionProvider);
      final repository = getIt<BillRepository>();
      final notifier = BillDetailNotifier(repository, initialBill);
      registerRealtimeInterest(
        ref,
        key: RealtimeInterestKey.billDetail(
          initialBill.groupId,
          initialBill.id,
        ),
        resourceVersion: () => notifier.resourceVersion,
        refresh: () => notifier.loadBillDetail(
          billId: initialBill.id,
          groupId: initialBill.groupId,
          background: true,
        ),
      );
      return notifier;
    });
